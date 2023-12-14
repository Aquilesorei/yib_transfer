import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as fileUtil;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import '../models/PeerEndpoint.dart';
typedef void OnDownloadProgressCallback(int receivedBytes, int totalBytes);
typedef void OnUploadProgressCallback(String fileName,int sentBytes, int totalBytes);

class FileService {
  static bool trustSelfSigned = true;

  static HttpClient getHttpClient() {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => trustSelfSigned);

    return httpClient;
  }

  static String baseUrl = '127.0.0.1:5007';


  static Future<String> fileDelete(String fileName) async {
    var httpClient = getHttpClient();

    final url = Uri.encodeFull('$baseUrl/api/file/$fileName');

    var httpRequest = await httpClient.deleteUrl(Uri.parse(url));

    var httpResponse = await httpRequest.close();

    var response = await readResponseAsString(httpResponse);

    return response;
  }

  static Future<String> fileUpload({required File file, required OnUploadProgressCallback onUploadProgress}) async {

    final url = '$baseUrl/api/file';

    final fileStream = file.openRead();

    int totalByteLength = file.lengthSync();

    final httpClient = getHttpClient();

    final request = await httpClient.postUrl(Uri.parse(url));

    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.binary);

    request.headers.add("filename", fileUtil.basename(file.path));

    request.contentLength = totalByteLength;
    var sanitizedFilename =
    basename(file.path).replaceAll(RegExp(r'[^\w\s.-]'), '_');
    int byteCount = 0;
    Stream<List<int>> streamUpload = fileStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;

          onUploadProgress(sanitizedFilename,byteCount, totalByteLength);
          // CALL STATUS CALLBACK;

          sink.add(data);
        },
        handleError: (error, stack, sink) {
          print(error.toString());
        },
        handleDone: (sink) {
          sink.close();
          // UPLOAD DONE;
        },
      ),
    );

    await request.addStream(streamUpload);

    final httpResponse = await request.close();

    if (httpResponse.statusCode != 200) {
      throw Exception('Error uploading file');
    } else {
      return await readResponseAsString(httpResponse);
    }
  }

  static Future<String> fileUploadMultipart(
      {required File file,required PeerEndpoint endpoint, required OnUploadProgressCallback onUploadProgress}) async {
    var uri = Uri.http(endpoint.format(), '/file');

    final httpClient = getHttpClient();

    final request = await httpClient.postUrl(uri);

    int byteCount = 0;

    var multipart = await http.MultipartFile.fromPath(fileUtil.basename(file.path), file.path);


    var requestMultipart = http.MultipartRequest("POST", uri);

    requestMultipart.files.add(multipart);

    var msStream = requestMultipart.finalize();

    var totalByteLength = requestMultipart.contentLength;

    request.contentLength = totalByteLength;
    var sanitizedFilename =
    basename(file.path).replaceAll(RegExp(r'[^\w\s.-]'), '_');

    request.headers.set(
        HttpHeaders.contentTypeHeader, requestMultipart.headers[HttpHeaders.contentTypeHeader] as Object);
    request.headers.set('Content-Disposition',sanitizedFilename );

    Stream<List<int>> streamUpload = msStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);

          byteCount += data.length;

          onUploadProgress(sanitizedFilename,byteCount, totalByteLength);
          // CALL STATUS CALLBACK;
                },
        handleError: (error, stack, sink) {
          throw error;
        },
        handleDone: (sink) {
          sink.close();
          // UPLOAD DONE;
        },
      ),
    );

    await request.addStream(streamUpload);

    final httpResponse = await request.close();
//
    var statusCode = httpResponse.statusCode;

    if (statusCode ~/ 100 != 2) {
      throw Exception('Error uploading file, Status code: ${httpResponse.statusCode}');
    } else {
      return await readResponseAsString(httpResponse);
    }
  }

  static Future<Future> fileDownload(
      {required String fileName, required OnUploadProgressCallback onDownloadProgress}) async {

    final url = Uri.encodeFull('$baseUrl/api/file/$fileName');

    final httpClient = getHttpClient();

    final request = await httpClient.getUrl(Uri.parse(url));

    request.headers.add(HttpHeaders.contentTypeHeader, "application/octet-stream");

    var httpResponse = await request.close();

    int byteCount = 0;
    int totalBytes = httpResponse.contentLength;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    //appDocPath = "/storage/emulated/0/Download";

    File file = File("$appDocPath/$fileName");

    var raf = file.openSync(mode: FileMode.write);

    Completer completer = Completer<String>();
    var sanitizedFilename =
    basename(file.path).replaceAll(RegExp(r'[^\w\s.-]'), '_');
    httpResponse.listen(
      (data) {
        byteCount += data.length;

        raf.writeFromSync(data);

        onDownloadProgress(sanitizedFilename,byteCount, totalBytes);
            },
      onDone: () {
        raf.closeSync();

        completer.complete(file.path);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  static Future<String> readResponseAsString(HttpClientResponse response) {
    var completer = Completer<String>();
    var contents = StringBuffer();
    response.transform(utf8.decoder).listen((String data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }
}
