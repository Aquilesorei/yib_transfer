
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/FileTransferInfo.dart';

class FileTransferProvider extends ChangeNotifier {
  final Map<String,FileTransferInfo> _fileTransfers = {};
  
  // Aggregate stats
  int _totalFiles = 0;
  int _processedFiles = 0;
  int _totalBatchSize = 0;
  int _totalBytesTransferred = 0;

  List<FileTransferInfo> get fileTransfers => _fileTransfers.values.toList();
  
  int get totalFiles => _totalFiles;
  int get processedFiles => _processedFiles;
  int get totalBatchSize => _totalBatchSize;
  int get totalBytesTransferred => _totalBytesTransferred;
  
  double get aggregateProgress {
    if (_totalBatchSize == 0) return 0.0;
    return _totalBytesTransferred / _totalBatchSize;
  }
  
  void startBatch(int fileCount, int totalSize) {
    _totalFiles = fileCount;
    _totalBatchSize = totalSize;
    _processedFiles = 0;
    _totalBytesTransferred = 0;
    _fileTransfers.clear();
    notifyListeners();
  }

  void updateProgress(String fileName,int fileSize,double progress,int byteSent,[CancelToken? token]) {

    if(_fileTransfers[fileName] == null){
      _fileTransfers[fileName] = FileTransferInfo(fileName, fileSize, progress,byteSent,token);
    }else{
      _fileTransfers[fileName]!.take(fileName,fileSize, progress,byteSent);
    }
    
    // Update aggregate stats
    _totalBytesTransferred = _fileTransfers.values.fold(0, (sum, info) => sum + info.byteSent);
    _processedFiles = _fileTransfers.values.where((f) => f.progress >= 1.0).length;

    notifyListeners();

  }
}