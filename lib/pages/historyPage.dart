
import 'package:flutter/material.dart';

import '../data/DatabaseManager.dart';


class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stream<List<Map<String, dynamic>>>>(
      future: DatabaseManager.streamAllHistoryItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Loading indicator while waiting for data.
        }

        final historyItemsStream = snapshot.data;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: historyItemsStream,
          builder: (context, streamSnapshot) {
            if (streamSnapshot.hasError) {
              return Text('Stream Error: ${streamSnapshot.error}');
            }

            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Loading indicator while waiting for data.
            }

            final historyItems = streamSnapshot.data ?? []; // History items data from the stream.

            // Build your widget using historyItems.
            // For example, you can create a ListView to display the history items.
            return ListView.builder(
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final historyItem = historyItems[index];
                // Create a widget to display historyItem data.
                return ListTile(
                  title: Text(historyItem['fileName']),
                  // ... Other historyItem data.
                );
              },
            );
          },
        );
      },
    );
  }
}
