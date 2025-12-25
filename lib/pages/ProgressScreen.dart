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
      body: provider.fileTransfers.isEmpty
          ? const Center(
              child: Text(
                "No Transfer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : Column(
              children: [
                if (provider.totalFiles > 1)
                  Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Overall Progress",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: provider.aggregateProgress),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${provider.processedFiles} of ${provider.totalFiles} files"),
                              Text("${(provider.aggregateProgress * 100).toStringAsFixed(1)}%"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.fileTransfers.length,
                    itemBuilder: (context, index) => ProgressWidget(index),
                  ),
                ),
              ],
            ),
    );
  }
}
