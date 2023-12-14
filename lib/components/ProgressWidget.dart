
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/FileTransferProvider.dart';
import '../utils.dart';

class ProgressWidget extends StatelessWidget {
  final int index;


  const ProgressWidget(this.index, {super.key});


  @override
  Widget build(BuildContext context) {
    final provider = context.read<FileTransferProvider>();
    final transferInfo = provider.fileTransfers[index];


    return transferInfo.isCanceled() ? Container() : Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(transferInfo.fileName,overflow: TextOverflow.ellipsis,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Size: ${getFormattedFileSize(transferInfo.fileSize)} "),
            if(transferInfo.progress != 1.0 ) Text("speed: ${getFormattedFileSize(transferInfo.speed)}/s "),
            LinearProgressIndicator(value: transferInfo.progress),
          ],
        ),
        leading:  Text(
          "${(transferInfo.progress * 100).round()}%",
          style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),

        trailing:  transferInfo.progress == 1.0 ?  const Icon(Icons.done,color: Colors.green,size: 64,) :  IconButton(onPressed:transferInfo.cancel, icon: const Icon(Icons.cancel)),
      )
    );
  }
}