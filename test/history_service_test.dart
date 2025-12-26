import 'package:flutter_test/flutter_test.dart';
import 'package:ztransfer/services/history_service.dart';

void main() {
  group('TransferHistoryItem', () {
    test('toJson and fromJson are symmetric', () {
      final original = TransferHistoryItem(
        id: '12345',
        fileName: 'test.pdf',
        fileSize: 1024,
        timestamp: DateTime(2024, 1, 15, 10, 30),
        direction: TransferDirection.sent,
        status: TransferStatus.completed,
        peerAddress: '192.168.1.1',
      );

      final json = original.toJson();
      final restored = TransferHistoryItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.fileName, equals(original.fileName));
      expect(restored.fileSize, equals(original.fileSize));
      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.direction, equals(original.direction));
      expect(restored.status, equals(original.status));
      expect(restored.peerAddress, equals(original.peerAddress));
    });

    test('sent factory creates correct item', () {
      final item = TransferHistoryItem.sent(
        fileName: 'document.pdf',
        fileSize: 2048,
        peerAddress: '10.0.0.1',
      );

      expect(item.direction, equals(TransferDirection.sent));
      expect(item.status, equals(TransferStatus.completed));
      expect(item.fileName, equals('document.pdf'));
      expect(item.fileSize, equals(2048));
    });

    test('received factory creates correct item', () {
      final item = TransferHistoryItem.received(
        fileName: 'photo.jpg',
        fileSize: 4096,
      );

      expect(item.direction, equals(TransferDirection.received));
      expect(item.status, equals(TransferStatus.completed));
      expect(item.fileName, equals('photo.jpg'));
      expect(item.fileSize, equals(4096));
    });

    test('failed factory creates correct item', () {
      final item = TransferHistoryItem.failed(
        fileName: 'broken.zip',
        direction: TransferDirection.sent,
        errorMessage: 'Connection timeout',
      );

      expect(item.direction, equals(TransferDirection.sent));
      expect(item.status, equals(TransferStatus.failed));
      expect(item.fileName, equals('broken.zip'));
      expect(item.errorMessage, equals('Connection timeout'));
      expect(item.fileSize, equals(0));
    });

    test('handles null optional fields', () {
      final item = TransferHistoryItem(
        id: '999',
        fileName: 'file.txt',
        fileSize: 100,
        timestamp: DateTime.now(),
        direction: TransferDirection.received,
        status: TransferStatus.completed,
      );

      final json = item.toJson();
      expect(json['peerAddress'], isNull);
      expect(json['errorMessage'], isNull);

      final restored = TransferHistoryItem.fromJson(json);
      expect(restored.peerAddress, isNull);
      expect(restored.errorMessage, isNull);
    });
  });

  group('TransferDirection', () {
    test('contains sent and received values', () {
      expect(TransferDirection.values, contains(TransferDirection.sent));
      expect(TransferDirection.values, contains(TransferDirection.received));
    });
  });

  group('TransferStatus', () {
    test('contains all status values', () {
      expect(TransferStatus.values, contains(TransferStatus.completed));
      expect(TransferStatus.values, contains(TransferStatus.failed));
      expect(TransferStatus.values, contains(TransferStatus.cancelled));
    });
  });
}
