import 'package:flutter_test/flutter_test.dart';
import 'package:yib_transfer/utils.dart';

void main() {
  group('getFormattedFileSize', () {
    test('formats 0 bytes correctly', () {
      expect(getFormattedFileSize(0), equals('0 B'));
    });

    test('formats bytes correctly', () {
      expect(getFormattedFileSize(500), equals('500.00 B'));
    });

    test('formats kilobytes correctly', () {
      expect(getFormattedFileSize(1024), equals('1.00 KB'));
      expect(getFormattedFileSize(1536), equals('1.50 KB'));
    });

    test('formats megabytes correctly', () {
      expect(getFormattedFileSize(1048576), equals('1.00 MB'));
      expect(getFormattedFileSize(5242880), equals('5.00 MB'));
    });

    test('formats gigabytes correctly', () {
      expect(getFormattedFileSize(1073741824), equals('1.00 GB'));
    });

    test('handles withUnit=false', () {
      expect(getFormattedFileSize(1024, withUnit: false), equals('1.00'));
    });

    test('handles negative numbers', () {
      expect(getFormattedFileSize(-1), equals('0 B'));
    });
  });

  group('isPortAvailable', () {
    test('returns true for unused high port', () async {
      // Port 65535 is typically unused
      final result = await isPortAvailable(65534);
      expect(result, isTrue);
    });
  });

  group('findAvailablePort', () {
    test('returns a valid port number', () async {
      final port = await findAvailablePort();
      expect(port, greaterThan(0));
      expect(port, lessThanOrEqualTo(65535));
    });
  });

  group('getFilePath', () {
    test('categorizes audio files correctly', () {
      final path = getFilePath('song.mp3', 'audio/mpeg', '/base');
      expect(path, contains('Audio'));
    });

    test('categorizes video files correctly', () {
      final path = getFilePath('video.mp4', 'video/mp4', '/base');
      expect(path, contains('Video'));
    });

    test('categorizes image files correctly', () {
      final path = getFilePath('photo.jpg', 'image/jpeg', '/base');
      expect(path, contains('Image'));
    });

    test('categorizes APK files correctly', () {
      final path = getFilePath('app.apk', 'application/vnd.android.package-archive', '/base');
      expect(path, contains('App'));
    });

    test('categorizes PDF files correctly', () {
      final path = getFilePath('doc.pdf', 'application/pdf', '/base');
      expect(path, contains('Documents'));
    });

    test('puts unknown types in Others', () {
      final path = getFilePath('file.xyz', 'application/octet-stream', '/base');
      expect(path, contains('Others'));
    });
  });
}
