import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

/// Direction of file transfer
enum TransferDirection { sent, received }

/// Status of a transfer
enum TransferStatus { completed, failed, cancelled }

/// Represents a single transfer history entry
class TransferHistoryItem {
  final String id;
  final String fileName;
  final int fileSize;
  final DateTime timestamp;
  final TransferDirection direction;
  final TransferStatus status;
  final String? peerAddress;
  final String? errorMessage;

  TransferHistoryItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
    required this.direction,
    required this.status,
    this.peerAddress,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSize': fileSize,
        'timestamp': timestamp.toIso8601String(),
        'direction': direction.name,
        'status': status.name,
        'peerAddress': peerAddress,
        'errorMessage': errorMessage,
      };

  factory TransferHistoryItem.fromJson(Map<String, dynamic> json) =>
      TransferHistoryItem(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        fileSize: json['fileSize'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        direction: TransferDirection.values.byName(json['direction'] as String),
        status: TransferStatus.values.byName(json['status'] as String),
        peerAddress: json['peerAddress'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );

  /// Creates a new history item for a completed send
  factory TransferHistoryItem.sent({
    required String fileName,
    required int fileSize,
    String? peerAddress,
  }) =>
      TransferHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: fileSize,
        timestamp: DateTime.now(),
        direction: TransferDirection.sent,
        status: TransferStatus.completed,
        peerAddress: peerAddress,
      );

  /// Creates a new history item for a completed receive
  factory TransferHistoryItem.received({
    required String fileName,
    required int fileSize,
    String? peerAddress,
  }) =>
      TransferHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: fileSize,
        timestamp: DateTime.now(),
        direction: TransferDirection.received,
        status: TransferStatus.completed,
        peerAddress: peerAddress,
      );

  /// Creates a new history item for a failed transfer
  factory TransferHistoryItem.failed({
    required String fileName,
    required TransferDirection direction,
    String? errorMessage,
  }) =>
      TransferHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileSize: 0,
        timestamp: DateTime.now(),
        direction: direction,
        status: TransferStatus.failed,
        errorMessage: errorMessage,
      );
}

/// Service for managing transfer history with persistence
class HistoryService {
  static const String _dbName = 'transfer_history.db';
  static const String _storeName = 'history';

  static HistoryService? _instance;
  static HistoryService get instance {
    _instance ??= HistoryService._();
    return _instance!;
  }

  HistoryService._();

  Database? _db;
  final _store = stringMapStoreFactory.store(_storeName);
  final _historyController = StreamController<List<TransferHistoryItem>>.broadcast();

  /// Stream of history updates
  Stream<List<TransferHistoryItem>> get historyStream => _historyController.stream;

  /// Initialize the database
  Future<void> initialize() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  /// Add a new history item
  Future<void> addItem(TransferHistoryItem item) async {
    await _ensureInitialized();
    await _store.record(item.id).put(_db!, item.toJson());
    _notifyListeners();
  }

  /// Get all history items, sorted by timestamp descending
  Future<List<TransferHistoryItem>> getHistory({int limit = 100}) async {
    await _ensureInitialized();

    final finder = Finder(
      sortOrders: [SortOrder('timestamp', false)],
      limit: limit,
    );

    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => TransferHistoryItem.fromJson(r.value)).toList();
  }

  /// Get history items by direction
  Future<List<TransferHistoryItem>> getHistoryByDirection(
    TransferDirection direction, {
    int limit = 50,
  }) async {
    await _ensureInitialized();

    final finder = Finder(
      filter: Filter.equals('direction', direction.name),
      sortOrders: [SortOrder('timestamp', false)],
      limit: limit,
    );

    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => TransferHistoryItem.fromJson(r.value)).toList();
  }

  /// Get history items by status
  Future<List<TransferHistoryItem>> getHistoryByStatus(
    TransferStatus status, {
    int limit = 50,
  }) async {
    await _ensureInitialized();

    final finder = Finder(
      filter: Filter.equals('status', status.name),
      sortOrders: [SortOrder('timestamp', false)],
      limit: limit,
    );

    final records = await _store.find(_db!, finder: finder);
    return records.map((r) => TransferHistoryItem.fromJson(r.value)).toList();
  }

  /// Delete a history item
  Future<void> deleteItem(String id) async {
    await _ensureInitialized();
    await _store.record(id).delete(_db!);
    _notifyListeners();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _ensureInitialized();
    await _store.delete(_db!);
    _notifyListeners();
  }

  /// Get total count of transfers
  Future<int> getTransferCount() async {
    await _ensureInitialized();
    return await _store.count(_db!);
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureInitialized();

    final allItems = await getHistory(limit: 1000);

    int totalSent = 0;
    int totalReceived = 0;
    int totalFailed = 0;
    int totalBytesSent = 0;
    int totalBytesReceived = 0;

    for (var item in allItems) {
      if (item.status == TransferStatus.completed) {
        if (item.direction == TransferDirection.sent) {
          totalSent++;
          totalBytesSent += item.fileSize;
        } else {
          totalReceived++;
          totalBytesReceived += item.fileSize;
        }
      } else if (item.status == TransferStatus.failed) {
        totalFailed++;
      }
    }

    return {
      'totalSent': totalSent,
      'totalReceived': totalReceived,
      'totalFailed': totalFailed,
      'totalBytesSent': totalBytesSent,
      'totalBytesReceived': totalBytesReceived,
    };
  }

  Future<void> _ensureInitialized() async {
    if (_db == null) {
      await initialize();
    }
  }

  void _notifyListeners() async {
    final history = await getHistory();
    _historyController.add(history);
  }

  void dispose() {
    _historyController.close();
    _db?.close();
  }
}
