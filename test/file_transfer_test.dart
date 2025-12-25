import 'package:flutter_test/flutter_test.dart';
import 'package:yib_transfer/models/PeerEndpoint.dart';
import 'package:yib_transfer/routes/file_transfer.dart';

void main() {
  group('isValidEnPoint', () {
    test('accepts valid IP:port format', () {
      expect(isValidEnPoint('192.168.1.1:5007'), isTrue);
      expect(isValidEnPoint('10.0.0.1:8080'), isTrue);
      expect(isValidEnPoint('172.16.0.1:1234'), isTrue);
    });

    test('rejects invalid IPs', () {
      expect(isValidEnPoint('256.1.1.1:5007'), isFalse);
      expect(isValidEnPoint('192.168.1:5007'), isFalse);
      expect(isValidEnPoint('192.168.1.1.1:5007'), isFalse);
      expect(isValidEnPoint('abc.def.ghi.jkl:5007'), isFalse);
    });

    test('rejects invalid ports', () {
      expect(isValidEnPoint('192.168.1.1:0'), isFalse);
      expect(isValidEnPoint('192.168.1.1:65536'), isFalse);
      expect(isValidEnPoint('192.168.1.1:abc'), isFalse);
      expect(isValidEnPoint('192.168.1.1:-1'), isFalse);
    });

    test('rejects invalid formats', () {
      expect(isValidEnPoint('192.168.1.1'), isFalse);
      expect(isValidEnPoint(':5007'), isFalse);
      expect(isValidEnPoint(''), isFalse);
      expect(isValidEnPoint('192.168.1.1:5007:extra'), isFalse);
    });
  });

  group('isValidFilename', () {
    test('accepts valid filenames', () {
      expect(isValidFilename('document.pdf'), isTrue);
      expect(isValidFilename('my-file_v2.txt'), isTrue);
      expect(isValidFilename('photo (1).jpg'), isTrue);
    });

    test('rejects path traversal attempts', () {
      expect(isValidFilename('../etc/passwd'), isFalse);
      expect(isValidFilename('..\\windows\\system32'), isFalse);
      expect(isValidFilename('file/../other'), isFalse);
    });

    test('rejects path separators', () {
      expect(isValidFilename('/etc/passwd'), isFalse);
      expect(isValidFilename('C:\\Windows\\file.txt'), isFalse);
    });

    test('rejects null bytes', () {
      expect(isValidFilename('file\x00.txt'), isFalse);
    });

    test('rejects empty filenames', () {
      expect(isValidFilename(''), isFalse);
    });

    test('rejects too long filenames', () {
      final longName = 'a' * 256;
      expect(isValidFilename(longName), isFalse);
    });
  });

  group('TransferError', () {
    test('provides user-friendly messages for each error type', () {
      final timeout = TransferError(
        type: TransferErrorType.connectionTimeout,
        message: 'test',
      );
      expect(timeout.userFriendlyMessage, contains('timed out'));

      final refused = TransferError(
        type: TransferErrorType.connectionRefused,
        message: 'test',
      );
      expect(refused.userFriendlyMessage, contains('refused'));

      final unreachable = TransferError(
        type: TransferErrorType.networkUnreachable,
        message: 'test',
      );
      expect(unreachable.userFriendlyMessage, contains('unreachable'));

      final tooLarge = TransferError(
        type: TransferErrorType.fileTooLarge,
        message: 'test',
      );
      expect(tooLarge.userFriendlyMessage, contains('too large'));

      final invalid = TransferError(
        type: TransferErrorType.invalidFilename,
        message: 'test',
      );
      expect(invalid.userFriendlyMessage, contains('Invalid'));

      final cancelled = TransferError(
        type: TransferErrorType.cancelled,
        message: 'test',
      );
      expect(cancelled.userFriendlyMessage, contains('cancelled'));
    });
  });

  group('TransferResult', () {
    test('success result is marked as successful', () {
      final result = TransferResult.success('file.txt');
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.fileName, equals('file.txt'));
    });

    test('failure result contains error', () {
      final error = TransferError(
        type: TransferErrorType.connectionTimeout,
        message: 'timeout',
      );
      final result = TransferResult.failure('file.txt', error);
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.fileName, equals('file.txt'));
    });
  });
}
