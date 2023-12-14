
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/FileTransferInfo.dart';

class FileTransferProvider extends ChangeNotifier {
  final Map<String,FileTransferInfo> _fileTransfers = {};

  List<FileTransferInfo> get fileTransfers => _fileTransfers.values.toList();



  void updateProgress(String fileName,int fileSize,double progress,int byteSent,[CancelToken? token]) {

    if(_fileTransfers[fileName] == null){
      _fileTransfers[fileName] = FileTransferInfo(fileName, fileSize, progress,byteSent,token);
    }else{
      _fileTransfers[fileName]!.take(fileName,fileSize, progress,byteSent);
    }

      notifyListeners();

  }
}