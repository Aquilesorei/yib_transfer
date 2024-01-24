import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:yib_transfer/models/FileTransferInfo.dart';
import 'package:yib_transfer/routes/routes.dart';
import 'package:yifi/yifi.dart';

import '../Providers/FileTransferProvider.dart';
import '../models/PeerEndpoint.dart';

import '../services/file_service.dart';
import '../utils.dart';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class FileTransfer {
  int port = 5007;
  String initialEndpoint = "";
  bool started = false;
  PeerEndpoint? currentEndPoint;

  static FileTransfer? _instance;

  static FileTransfer get instance {
    _instance ??= FileTransfer._();
    return _instance!;
  }

  FileTransfer._();

  Set<PeerEndpoint> connectedEndpoints = {};



  Future<void> startServer({
    required Function(PeerEndpoint) onEndpointRegistered,
    required Function(File) onFileReceived,
    required FileTransferProvider provider,
  }) async {
    if (!started) {
      started = true;

      final availablePort = await findAvailablePort();
      port = availablePort;
      if (kDebugMode) {
        print('Available port: $availablePort');
      }

      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

      String? wifiIP = await NetworkInfo().getWifiIP();
      initialEndpoint = wifiIP ?? "";
      final res = await getLocalIpAddress2();
      if (res != null) {
        initialEndpoint = res;
      }
      if (Platform.isAndroid) {
        initialEndpoint = (await Yifi.getIp()) ?? "";
      }

      if (initialEndpoint.isNotEmpty) {
        currentEndPoint = PeerEndpoint(initialEndpoint, port);
        connectedEndpoints.add(currentEndPoint!);
      }
      print('Server listening on port $port ip :$res');

      await for (var request in server) {
        _handleRequest(
          request,
          onEndpointRegistered,
          onFileReceived,
          provider,
        );
      }
    }
  }

  Future<void> _handleRequest(
      HttpRequest request,
      Function(PeerEndpoint) onEndpointRegistered,
      Function(File) onFileReceived,
      FileTransferProvider provider,
      ) async {
    if (request.method == 'POST' && request.uri.path == '/register') {
      var content = await utf8.decoder.bind(request).join();

      String? clientIpAddress = request.connectionInfo?.remoteAddress.address;
      int?  clientPort = request.connectionInfo?.remotePort;

     // print("client ip $clientIpAddress");
      Map<String, dynamic> endpointData = json.decode(content);

      var pend = PeerEndpoint.fromJsonMap(endpointData);
      if(pend.ip != clientIpAddress){

        pend = PeerEndpoint(clientIpAddress!, clientPort!);
      }

      onEndpointRegistered(pend);

      request.response
          .write(serializeEndpointList(connectedEndpoints.toList()));
      await request.response.close();

    } else if (request.method == 'POST' && request.uri.path == '/file') {
      Routes.toProgress();
      final contentDisposition = request.headers['content-disposition'];
      String fileName = contentDisposition?.first ?? "ff";

      fileName = Uri.decodeComponent(fileName);


      final mimeType =
          request.headers[Headers.contentTypeHeader]?.first ?? "application/octet-stream";

       String path = await getDownloadFolder(fileName, mimeType);
       path = await handleFileDuplication(path);

      var file = File(path);
      var totalBytes = 0;
      fileName = basename(path);

      await for (var chunk in request) {
        totalBytes += chunk.length;
        await file.writeAsBytes(chunk, mode: FileMode.append);
        // Calculate and print progress
        double progress = totalBytes / request.contentLength;

        provider.updateProgress(fileName, request.contentLength, progress, totalBytes, null);
        //print('Progress: ${(progress * 100).toStringAsFixed(2)}%');
      }
      onFileReceived(file);
      request.response.write('File received');
      await request.response.close();
    } else {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
    }
  }


  Future<void> sendFiles(List<File> files, FileTransferProvider provider) async {
    Routes.toProgress();

    final futures = <Future<void>>[];

    for (var endpoint in connectedEndpoints) {
      if (endpoint.format() != currentEndPoint!.format()) {
        for (var file in files) {
          futures.add(sendFileToServer(file, endpoint, provider));
        }
      }
    }

    await Future.wait(futures);
  }

  Future<void> sendFileToServer(
      File file, PeerEndpoint endpoint, FileTransferProvider provider) async {
    final serverUrl = "http://${endpoint.format()}/file";
    final len = await file.length();

    try {
      final dio = Dio();
      final filename = basename(file.path);
      final sanitizedFilename = Uri.encodeComponent(filename);



      String? mimeType = lookupMimeType(file.path) ;
      mimeType ??=  "application/octet-stream";
      final options = Options(
        headers: {
          'content-disposition': sanitizedFilename,
          'content-type':mimeType,
          Headers.contentLengthHeader: len,
        },
      );

       var cancelToken = CancelToken();
      await dio.post(
           cancelToken : cancelToken,
          serverUrl, data: file.openRead(), options: options,
          onSendProgress: (int sent, int total) {
        double progress = sent / total;

        /// print(progress);
        provider.updateProgress(filename , total, progress,sent,cancelToken);
      });

      if (kDebugMode) {
        print('File successfully sent to server.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending file: $e');
      }
    }
  }



  Future<bool> register(PeerEndpoint endpoint) async {
    var url = Uri.http(endpoint.format(), '/register');

    var headers = {'Content-Type': 'application/json'};
    var jsonPayload = jsonEncode(currentEndPoint!.toJsonMap());

    try {
      var response = await http.post(
        url,
        headers: headers,
        body: jsonPayload,
      );

      if (response.statusCode == 200) {
        List<PeerEndpoint> endpoints = deserializeEndpointList(response.body);
        print('Registered at ${endpoint.format()}');

        connectedEndpoints.remove(currentEndPoint);

        currentEndPoint == endpoints.firstWhere((element) => element.port == currentEndPoint!.port,orElse: ()=> currentEndPoint!);

        connectedEndpoints.addAll(endpoints.toSet());
        Routes.toTransfer();
        return true;
      } else {
        if (kDebugMode) {
          print(
              'Failed to register at ${endpoint.format()}. Status code: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during registration: $e');
      }
      Routes.toHome();
      return false;
    }
  }
}
