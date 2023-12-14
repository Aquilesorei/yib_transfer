import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/FileTransferProvider.dart';
import '../components/ProgressWidget.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileTransferProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('File Transfers Progress')),
      body:provider.fileTransfers.isEmpty ? const Center(child: Text("No Transfer",style: TextStyle(fontWeight: FontWeight.bold),)) : ListView.builder(
        itemCount: provider.fileTransfers.length,
        itemBuilder: (context, index) => ProgressWidget(index),
      ),
    );
  }
}
