# ZTransfer Protocol Documentation

## Overview

ZTransfer is a **peer-to-peer file transfer protocol** over local WiFi using HTTP. It enables **multi-device mesh networking** where any device can send files to all connected peers simultaneously.

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Device A   │     │  Device B   │     │  Device C   │
│             │     │             │     │             │
│ ┌─────────┐ │     │ ┌─────────┐ │     │ ┌─────────┐ │
│ │ Server  │◄├─────┼─┤ Client  │ │     │ │ Client  │ │
│ │ :5007   │ │     │ └─────────┘ │     │ └─────────┘ │
│ └─────────┘ │     │ ┌─────────┐ │     │ ┌─────────┐ │
│ ┌─────────┐ │     │ │ Server  │◄├─────┼─┤ Client  │ │
│ │ Client  ├─┼─────┼►│ :5007   │ │     │ └─────────┘ │
│ └─────────┘ │     │ └─────────┘ │     │ ┌─────────┐ │
│             │     │             │     │ │ Server  │ │
│             │     │             │     │ │ :5007   │ │
│             │     │             │     │ └─────────┘ │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Each device runs both a server AND client** - allowing bidirectional transfers.

---

## Protocol Endpoints

| Endpoint    | Method | Purpose                    |
| ----------- | ------ | -------------------------- |
| `/register` | POST   | Peer discovery & mesh sync |
| `/file`     | POST   | Stream file with progress  |

---

## Phase 1: Server Initialization

When ZTransfer launches:

```dart
// 1. Find available port (default 5007)
port = await findAvailablePort();

// 2. Bind HTTP server to all interfaces
server = await HttpServer.bind(InternetAddress.anyIPv4, port);

// 3. Get device's WiFi IP
initialEndpoint = await NetworkInfo().getWifiIP();

// 4. Create identity
currentEndPoint = PeerEndpoint(initialEndpoint, port);
connectedEndpoints.add(currentEndPoint);

// 5. Listen for requests
await for (var request in server) {
  _handleRequest(request);
}
```

---

## Phase 2: Peer Discovery (Mesh Registration)

### Registration Request

```http
POST /register HTTP/1.1
Host: 192.168.1.101:5007
Content-Type: application/json

{"ip": "192.168.1.100", "port": 5007}
```

### Registration Response

```http
HTTP/1.1 200 OK
Content-Type: application/json

[
  {"ip": "192.168.1.100", "port": 5007},
  {"ip": "192.168.1.101", "port": 5007},
  {"ip": "192.168.1.102", "port": 5007}
]
```

### Multi-Device Mesh Formation

```
Step 1: A starts (knows only itself)
        A: [A]

Step 2: B registers with A
        A: [A, B]  →  responds with [A, B]
        B: [A, B]

Step 3: C registers with A
        A: [A, B, C]  →  responds with [A, B, C]
        C: [A, B, C]

Result: All devices know about each other!
```

### Security: IP Verification

```dart
// Server verifies sender's actual IP matches claimed IP
String? actualIp = request.connectionInfo?.remoteAddress.address;
if (pend.ip != actualIp) {
  pend = PeerEndpoint(actualIp!, actualPort);  // Override with real IP
}
```

---

## Phase 3: File Transfer

### Send Request

```http
POST /file HTTP/1.1
Host: 192.168.1.101:5007
Content-Disposition: photo.jpg
Content-Type: image/jpeg
Content-Length: 5242880

[BINARY STREAM...]
```

### Sender Implementation

```dart
Future<TransferResult> sendFileToServer(File file, PeerEndpoint endpoint) {
  // Stream file directly from disk (memory efficient)
  await dio.post(
    "http://${endpoint.format()}/file",
    data: file.openRead(),  // ← Streaming, not buffered
    options: Options(headers: {
      'content-disposition': Uri.encodeComponent(filename),
      'content-type': mimeType,
      'content-length': fileSize,
    }),
    onSendProgress: (sent, total) {
      updateProgress(sent / total);
    },
  );
}
```

### Receiver Implementation

```dart
Future<void> _handleFileRequest(HttpRequest request) {
  // 1. Validate filename (security)
  if (!isValidFilename(fileName)) return error;

  // 2. Validate size (max 5GB)
  if (request.contentLength > maxTransferFileSize) return error;

  // 3. Stream chunks to disk
  await for (var chunk in request) {
    totalBytes += chunk.length;
    await file.writeAsBytes(chunk, mode: FileMode.append);
    updateProgress(totalBytes / request.contentLength);
  }
}
```

---

## Phase 4: Multi-Device Broadcast

**Key Feature**: Send to ALL connected devices at once!

```dart
Future<void> sendFiles(List<File> files) {
  for (var endpoint in connectedEndpoints) {
    if (endpoint != currentEndPoint) {  // Skip self
      for (var file in files) {
        await sendFileToServer(file, endpoint);
      }
    }
  }
}
```

### Broadcast Diagram

```
Device A sends "document.pdf"
         │
         ├────► Device B: ✓ Received
         │
         ├────► Device C: ✓ Received
         │
         └────► Device D: ✓ Received

One send = All devices receive!
```

---

## Security Features

| Feature                       | Implementation                                 |
| ----------------------------- | ---------------------------------------------- |
| **Path Traversal Prevention** | Blocks `..`, `/`, `\`, null bytes in filenames |
| **IP Spoofing Prevention**    | Verifies actual connection IP vs claimed IP    |
| **File Size Limit**           | Max 5GB per file                               |
| **Filename Length**           | Max 255 characters                             |
| **Partial File Cleanup**      | Deletes incomplete files on error              |

```dart
bool isValidFilename(String filename) {
  if (filename.contains('..')) return false;      // Path traversal
  if (filename.contains('/')) return false;       // Unix path
  if (filename.contains('\\')) return false;      // Windows path
  if (filename.contains('\x00')) return false;    // Null byte
  if (filename.length > 255) return false;        // Too long
  return true;
}
```

---

## Error Handling

| Error Type           | Cause              | User Message                           |
| -------------------- | ------------------ | -------------------------------------- |
| `connectionTimeout`  | Peer offline/slow  | "Is the receiver on the same network?" |
| `connectionRefused`  | App not running    | "Make sure the receiver app is open"   |
| `networkUnreachable` | WiFi disconnected  | "Check your WiFi connection"           |
| `fileTooLarge`       | >5GB               | "File is too large"                    |
| `invalidFilename`    | Security violation | "Invalid filename"                     |
| `cancelled`          | User cancelled     | "Transfer was cancelled"               |

---

## Data Structures

### PeerEndpoint

```dart
class PeerEndpoint {
  final String ip;    // "192.168.1.100"
  final int port;     // 5007

  String format() => '$ip:$port';
}
```

### TransferResult

```dart
class TransferResult {
  final bool success;
  final String fileName;
  final TransferError? error;
}
```

---

## Key Design Decisions

| Decision            | Rationale                                     |
| ------------------- | --------------------------------------------- |
| HTTP over raw TCP   | Firewall-friendly, well-tested                |
| Streaming I/O       | Memory efficient for large files              |
| Set\<PeerEndpoint\> | Prevents duplicate connections                |
| Dynamic port        | Avoids conflicts with other apps              |
| Mesh topology       | Any-to-any transfers, not just point-to-point |
| Singleton server    | One instance per app lifecycle                |
