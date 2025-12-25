import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:yib_transfer/routes/routes.dart';
import 'package:yifi/yifi.dart';

import '../Providers/FileTransferProvider.dart';
import '../models/PeerEndpoint.dart';
import '../utils.dart';
import '../services/history_service.dart';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';

/// Error types for file transfer operations
enum TransferErrorType {
  connectionTimeout,
  connectionRefused,
  networkUnreachable,
  fileTooLarge,
  invalidFilename,
  serverError,
  cancelled,
  unknown,
}

/// Represents an error during file transfer
class TransferError {
  final TransferErrorType type;
  final String message;
  final String? fileName;
  final Object? originalError;

  TransferError({
    required this.type,
    required this.message,
    this.fileName,
    this.originalError,
  });

  String get userFriendlyMessage {
    switch (type) {
      case TransferErrorType.connectionTimeout:
        return 'Connection timed out. Is the receiver connected to the same network?';
      case TransferErrorType.connectionRefused:
        return 'Connection refused. Make sure the receiver app is open.';
      case TransferErrorType.networkUnreachable:
        return 'Network unreachable. Check your WiFi connection.';
      case TransferErrorType.fileTooLarge:
        return 'File is too large to transfer.';
      case TransferErrorType.invalidFilename:
        return 'Invalid filename detected.';
      case TransferErrorType.serverError:
        return 'Server error occurred. Please try again.';
      case TransferErrorType.cancelled:
        return 'Transfer was cancelled.';
      case TransferErrorType.unknown:
        return message;
    }
  }
}

/// Result of a file transfer operation
class TransferResult {
  final bool success;
  final String fileName;
  final TransferError? error;

  TransferResult.success(this.fileName)
      : success = true,
        error = null;

  TransferResult.failure(this.fileName, this.error) : success = false;
}

/// Maximum file size for transfer (5GB)
const int maxTransferFileSize = 5 * 1024 * 1024 * 1024;

/// Validates a filename for security
bool isValidFilename(String filename) {
  // Check for path traversal attempts
  if (filename.contains('..') ||
      filename.contains('/') ||
      filename.contains('\\') ||
      filename.contains('\x00')) {
    return false;
  }

  // Check for empty or too long filenames
  if (filename.isEmpty || filename.length > 255) {
    return false;
  }

  return true;
}

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

  // Stream controllers for events
  final _errorController = StreamController<TransferError>.broadcast();
  final _transferCompleteController = StreamController<TransferResult>.broadcast();

  /// Stream of transfer errors for UI feedback
  Stream<TransferError> get onError => _errorController.stream;

  /// Stream of completed transfers
  Stream<TransferResult> get onTransferComplete => _transferCompleteController.stream;

  void dispose() {
    _errorController.close();
    _transferCompleteController.close();
  }

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
        print('Server starting on port: $availablePort');
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

      if (kDebugMode) {
        print('Server listening on $initialEndpoint:$port');
      }

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
    try {
      if (request.method == 'POST' && request.uri.path == '/register') {
        await _handleRegisterRequest(request, onEndpointRegistered);
      } else if (request.method == 'POST' && request.uri.path == '/file') {
        await _handleFileRequest(request, onFileReceived, provider);
      } else {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling request: $e');
      }
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _handleRegisterRequest(
    HttpRequest request,
    Function(PeerEndpoint) onEndpointRegistered,
  ) async {
    var content = await utf8.decoder.bind(request).join();

    String? clientIpAddress = request.connectionInfo?.remoteAddress.address;
    int? clientPort = request.connectionInfo?.remotePort;

    Map<String, dynamic> endpointData = json.decode(content);

    var pend = PeerEndpoint.fromJsonMap(endpointData);
    if (pend.ip != clientIpAddress) {
      pend = PeerEndpoint(clientIpAddress!, clientPort!);
    }

    onEndpointRegistered(pend);

    request.response.write(serializeEndpointList(connectedEndpoints.toList()));
    await request.response.close();
  }

  Future<void> _handleFileRequest(
    HttpRequest request,
    Function(File) onFileReceived,
    FileTransferProvider provider,
  ) async {
    Routes.toProgress();
    final contentDisposition = request.headers['content-disposition'];
    String fileName = contentDisposition?.first ?? "unknown_file";

    fileName = Uri.decodeComponent(fileName);

    // Security: Validate filename
    if (!isValidFilename(fileName)) {
      _errorController.add(TransferError(
        type: TransferErrorType.invalidFilename,
        message: 'Invalid filename received',
        fileName: fileName,
      ));
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Invalid filename');
      await request.response.close();
      return;
    }

    // Security: Validate file size
    if (request.contentLength > maxTransferFileSize) {
      _errorController.add(TransferError(
        type: TransferErrorType.fileTooLarge,
        message: 'File exceeds maximum size limit',
        fileName: fileName,
      ));
      request.response.statusCode = HttpStatus.requestEntityTooLarge;
      request.response.write('File too large');
      await request.response.close();
      return;
    }

    final mimeType =
        request.headers['content-type']?.first ?? "application/octet-stream";

    String path = await getDownloadFolder(fileName, mimeType);
    path = await handleFileDuplication(path);

    var file = File(path);
    var totalBytes = 0;
    fileName = basename(path);

    try {
      await for (var chunk in request) {
        totalBytes += chunk.length;
        await file.writeAsBytes(chunk, mode: FileMode.append);

        double progress = request.contentLength > 0
            ? totalBytes / request.contentLength
            : 0.0;

        provider.updateProgress(
            fileName, request.contentLength, progress, totalBytes, null);
      }

      onFileReceived(file);
      _transferCompleteController.add(TransferResult.success(fileName));
      
      // Record in history
      await HistoryService.instance.addItem(TransferHistoryItem.received(
        fileName: fileName,
        fileSize: totalBytes,
        peerAddress: request.connectionInfo?.remoteAddress.address,
      ));
      
      request.response.write('File received');
      await request.response.close();
    } catch (e) {
      // Clean up partial file on error
      if (await file.exists()) {
        await file.delete();
      }
      _errorController.add(TransferError(
        type: TransferErrorType.unknown,
        message: 'Error receiving file: $e',
        fileName: fileName,
        originalError: e,
      ));
      
      // Record failure in history
      await HistoryService.instance.addItem(TransferHistoryItem.failed(
        fileName: fileName,
        direction: TransferDirection.received,
        errorMessage: 'Error receiving file: $e',
      ));
      
      rethrow;
    }
  }

  Future<void> sendFiles(List<File> files, FileTransferProvider provider) async {
    if (files.isEmpty) return;

    // Calculate total size for batch tracking
    int totalSize = 0;
    for (var file in files) {
      try {
        totalSize += await file.length();
      } catch (_) {}
    }
    
    provider.startBatch(files.length, totalSize);

    Routes.toProgress();

    final results = <TransferResult>[];

    for (var endpoint in connectedEndpoints) {
      if (endpoint.format() != currentEndPoint?.format()) {
        for (var file in files) {
          final result = await sendFileToServer(file, endpoint, provider);
          results.add(result);
        }
      }
    }

    // Notify about any failures
    final failures = results.where((r) => !r.success).toList();
    if (failures.isNotEmpty && kDebugMode) {
      print('${failures.length} file(s) failed to send');
    }
  }

  Future<TransferResult> sendFileToServer(
    File file,
    PeerEndpoint endpoint,
    FileTransferProvider provider,
  ) async {
    final serverUrl = "http://${endpoint.format()}/file";
    final filename = basename(file.path);

    try {
      final len = await file.length();

      // Validate file size
      if (len > maxTransferFileSize) {
        final error = TransferError(
          type: TransferErrorType.fileTooLarge,
          message: 'File exceeds ${getFormattedFileSize(maxTransferFileSize)} limit',
          fileName: filename,
        );
        _errorController.add(error);
        return TransferResult.failure(filename, error);
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 30),
      ));

      final sanitizedFilename = Uri.encodeComponent(filename);

      String? mimeType = lookupMimeType(file.path);
      mimeType ??= "application/octet-stream";

      final options = Options(
        headers: {
          'content-disposition': sanitizedFilename,
          'content-type': mimeType,
          Headers.contentLengthHeader: len,
        },
      );

      var cancelToken = CancelToken();

      await dio.post(
        serverUrl,
        data: file.openRead(),
        options: options,
        cancelToken: cancelToken,
        onSendProgress: (int sent, int total) {
          double progress = total > 0 ? sent / total : 0.0;
          provider.updateProgress(filename, total, progress, sent, cancelToken);
        },
      );

      if (kDebugMode) {
        print('File sent successfully: $filename');
      }

      final result = TransferResult.success(filename);
      _transferCompleteController.add(result);

      // Record in history
      await HistoryService.instance.addItem(TransferHistoryItem.sent(
        fileName: filename,
        fileSize: len,
        peerAddress: endpoint.ip,
      ));

      return result;
    } on DioException catch (e) {
      final error = _mapDioError(e, filename);
      _errorController.add(error);

      // Record failure in history
      await HistoryService.instance.addItem(TransferHistoryItem.failed(
        fileName: filename,
        direction: TransferDirection.sent,
        errorMessage: error.userFriendlyMessage,
      ));

      return TransferResult.failure(filename, error);
    } catch (e) {
      final error = TransferError(
        type: TransferErrorType.unknown,
        message: 'Error sending file: $e',
        fileName: filename,
        originalError: e,
      );
      _errorController.add(error);

      // Record failure in history
      await HistoryService.instance.addItem(TransferHistoryItem.failed(
        fileName: filename,
        direction: TransferDirection.sent,
        errorMessage: error.userFriendlyMessage,
      ));

      return TransferResult.failure(filename, error);
    }
  }

  TransferError _mapDioError(DioException e, String filename) {
    TransferErrorType type;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        type = TransferErrorType.connectionTimeout;
        message = 'Connection timed out';
        break;
      case DioExceptionType.sendTimeout:
        type = TransferErrorType.connectionTimeout;
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        type = TransferErrorType.connectionTimeout;
        message = 'Receive timeout';
        break;
      case DioExceptionType.connectionError:
        type = TransferErrorType.networkUnreachable;
        message = 'Network unreachable';
        break;
      case DioExceptionType.cancel:
        type = TransferErrorType.cancelled;
        message = 'Transfer cancelled';
        break;
      case DioExceptionType.badResponse:
        type = TransferErrorType.serverError;
        message = 'Server error: ${e.response?.statusCode}';
        break;
      default:
        type = TransferErrorType.unknown;
        message = e.message ?? 'Unknown error';
    }

    return TransferError(
      type: type,
      message: message,
      fileName: filename,
      originalError: e,
    );
  }

  Future<bool> register(PeerEndpoint endpoint) async {
    var url = Uri.http(endpoint.format(), '/register');

    var headers = {'Content-Type': 'application/json'};
    var jsonPayload = jsonEncode(currentEndPoint!.toJsonMap());

    try {
      var response = await http
          .post(
            url,
            headers: headers,
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<PeerEndpoint> endpoints = deserializeEndpointList(response.body);
        if (kDebugMode) {
          print('Registered at ${endpoint.format()}');
        }

        connectedEndpoints.remove(currentEndPoint);
        currentEndPoint = endpoints.firstWhere(
          (element) => element.port == currentEndPoint!.port,
          orElse: () => currentEndPoint!,
        );
        connectedEndpoints.addAll(endpoints.toSet());
        Routes.toTransfer();
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to register: ${response.statusCode}');
        }
        return false;
      }
    } on TimeoutException {
      _errorController.add(TransferError(
        type: TransferErrorType.connectionTimeout,
        message: 'Registration timed out',
      ));
      Routes.toHome();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error during registration: $e');
      }
      _errorController.add(TransferError(
        type: TransferErrorType.unknown,
        message: 'Registration failed: $e',
        originalError: e,
      ));
      Routes.toHome();
      return false;
    }
  }
}
