import 'package:flutter/material.dart';
import 'package:yib_transfer/services/history_service.dart';
import '../utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransferHistoryItem> _allHistory = [];
  List<TransferHistoryItem> _sentHistory = [];
  List<TransferHistoryItem> _receivedHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();

    // Listen for history updates
    HistoryService.instance.historyStream.listen((history) {
      if (mounted) {
        _updateHistoryLists(history);
      }
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    try {
      await HistoryService.instance.initialize();
      final history = await HistoryService.instance.getHistory();
      _updateHistoryLists(history);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateHistoryLists(List<TransferHistoryItem> history) {
    setState(() {
      _allHistory = history;
      _sentHistory = history
          .where((h) => h.direction == TransferDirection.sent)
          .toList();
      _receivedHistory = history
          .where((h) => h.direction == TransferDirection.received)
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.history),
              text: 'All (${_allHistory.length})',
            ),
            Tab(
              icon: const Icon(Icons.upload),
              text: 'Sent (${_sentHistory.length})',
            ),
            Tab(
              icon: const Icon(Icons.download),
              text: 'Received (${_receivedHistory.length})',
            ),
          ],
        ),
        actions: [
          if (_allHistory.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'stats',
                  child: ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Statistics'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep, color: Colors.red),
                    title: Text('Clear History', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(_allHistory),
                _buildHistoryList(_sentHistory),
                _buildHistoryList(_receivedHistory),
              ],
            ),
    );
  }

  Widget _buildHistoryList(List<TransferHistoryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No transfers yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _HistoryItemCard(
            item: item,
            onDelete: () => _deleteItem(item),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'stats':
        _showStatistics();
        break;
      case 'clear':
        _confirmClearHistory();
        break;
    }
  }

  Future<void> _showStatistics() async {
    final stats = await HistoryService.instance.getStatistics();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow(
              icon: Icons.upload,
              label: 'Files Sent',
              value: '${stats['totalSent']}',
              subValue: getFormattedFileSize(stats['totalBytesSent']),
            ),
            const Divider(),
            _StatRow(
              icon: Icons.download,
              label: 'Files Received',
              value: '${stats['totalReceived']}',
              subValue: getFormattedFileSize(stats['totalBytesReceived']),
            ),
            const Divider(),
            _StatRow(
              icon: Icons.error_outline,
              label: 'Failed Transfers',
              value: '${stats['totalFailed']}',
              iconColor: Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all transfer history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.instance.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }

  Future<void> _deleteItem(TransferHistoryItem item) async {
    await HistoryService.instance.deleteItem(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${item.fileName}')),
      );
    }
  }
}

class _HistoryItemCard extends StatelessWidget {
  final TransferHistoryItem item;
  final VoidCallback onDelete;

  const _HistoryItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = item.status == TransferStatus.completed;
    final isSent = item.direction == TransferDirection.sent;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess
              ? (isSent ? Colors.blue : Colors.green)
              : Colors.red,
          child: Icon(
            isSuccess
                ? (isSent ? Icons.upload : Icons.download)
                : Icons.error_outline,
            color: Colors.white,
          ),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  getFormattedFileSize(item.fileSize),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(item.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (item.errorMessage != null)
              Text(
                item.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? iconColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
