# ZTransfer - Transfer Files Over WiFi

[![CI](https://github.com/Aquilesorei/ztransfer/actions/workflows/ci.yml/badge.svg)](https://github.com/Aquilesorei/ztransfer/actions/workflows/ci.yml)

ZTransfer is a simple and user-friendly application that allows you to transfer files between devices over a local WiFi network. This application provides a seamless and efficient way to share files without the need for an internet connection or any external cables.

## Features

- **Easy-to-Use Interface:** ZTransfer is designed with simplicity in mind. The intuitive user interface makes it easy for users of all levels to transfer files effortlessly.

- **Fast and Secure:** Transfer your files quickly over a secure local WiFi connection. No internet access or data usage required.

- **Cross-Platform Compatibility:** ZTransfer is available on multiple platforms, including Android, iOS, and desktop systems. Share files between different devices seamlessly.

- **No File Size Limit:** Transfer large files without worrying about file size restrictions. ZTransfer can handle files of various sizes with ease.

- **Multiple File Types:** Share a wide range of file types, including documents, photos, videos, music, and more.

- **Instant Connection:** Connect devices instantly by scanning a QR code or entering a simple code. No complex setup or configuration required.

## How to Use

1. **Download and Install:** Install ZTransfer from the respective app store on your device.

2. **Open the App:** Launch the ZTransfer app on both the sender and receiver devices.

3. **Connect Devices:** On the sender device, choose the "Send" option and on the receiver device, choose the "Receive" option.

4. **Establish Connection:** ZTransfer will generate a QR code or a code that you need to enter on the receiver device to establish a connection.

5. **Select Files:** Choose the files you want to transfer from the sender device.

6. **Initiate Transfer:** Tap the "Send" button to initiate the transfer. ZTransfer will use the local WiFi network to transfer the selected files.

7. **Completion:** Once the transfer is complete, you'll receive a notification on the receiver device. You can access the transferred files within the ZTransfer app.

## Protocol

ZTransfer uses a custom **peer-to-peer HTTP protocol** with mesh networking support. For full technical details, see [docs/PROTOCOL.md](docs/PROTOCOL.md).

### Key Features

- **Multi-Device Mesh**: Send files to ALL connected devices simultaneously
- **Streaming I/O**: Files stream directly from/to disk (memory efficient)
- **Peer Discovery**: Devices register and share their peer lists automatically

### Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Device A   │◄───►│  Device B   │◄───►│  Device C   │
│  Server +   │     │  Server +   │     │  Server +   │
│  Client     │     │  Client     │     │  Client     │
└─────────────┘     └─────────────┘     └─────────────┘
         ▲                                     │
         └─────────────────────────────────────┘
              Any device can send to any other
```

### Endpoints

| Endpoint    | Method | Purpose                    |
| ----------- | ------ | -------------------------- |
| `/register` | POST   | Peer discovery & mesh sync |
| `/file`     | POST   | Stream file with progress  |

### Security

- Path traversal prevention (blocks `../` attacks)
- IP verification (prevents spoofing)
- 5GB file size limit
- Partial file cleanup on errors

## Development

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.1.0
- Android Studio / Xcode (for mobile builds)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/Aquilesorei/ztransfer.git
cd ztransfer

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running Tests

```bash
flutter test
```

### Building

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# Web
flutter build web
```

## CI/CD

This project uses GitHub Actions for continuous integration:

- **CI Workflow** (`.github/workflows/ci.yml`): Runs on every push/PR

  - Code analysis
  - Unit tests
  - Debug builds (Android & Web)

- **Release Workflow** (`.github/workflows/release.yml`): Triggered on version tags
  - Builds release APK and AAB
  - Creates GitHub Release with artifacts

To create a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Privacy and Security

ZTransfer prioritizes your privacy and security. All file transfers occur over a local WiFi network, ensuring that your files remain within your control. No files are uploaded to the cloud or any external server during the transfer process.

## Feedback and Support

We value your feedback and are committed to improving the ZTransfer experience. If you encounter any issues, have suggestions for improvements, or need assistance, please don't hesitate to contact me at achillezongo07@gmail.com.

Thank you for using ZTransfer to simplify your file sharing needs!

## Author

👤 **Aquiles O Rei**
