

import 'package:dio/dio.dart';

import '../routes/TransferSpeedCalculator.dart';

class FileTransferInfo {
  String fileName;
   int fileSize;
  double progress;
  CancelToken?  cancelToken;
  int byteSent;
  final speedCalculator = TransferSpeedCalculator();



  int get speed {
    return speedCalculator.speed;
  }

  bool isCanceled() => cancelToken?.isCancelled ?? false;

  void take(String filename,int size , double pro,int sent){
    fileName = filename;
    fileSize = size;
    progress = pro;
    byteSent = sent;
    speedCalculator.updateSentBytes(byteSent);
  }

  void cancel(){
    if(cancelToken != null){
      cancelToken!.cancel('Upload canceled by user');
      speedCalculator.cancel();

    }
  }
  FileTransferInfo(this.fileName, this.fileSize, this.progress,this.byteSent,[this.cancelToken]);
}