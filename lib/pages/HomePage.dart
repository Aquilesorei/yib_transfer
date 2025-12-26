import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:ztransfer/Managers/HotspotManager.dart';
import 'package:ztransfer/Managers/WifiManager.dart';
import 'package:ztransfer/Providers/FileTransferProvider.dart';
import 'package:ztransfer/pages/PeerConnectionSetupPage.dart';

import '../components/AppDrawer.dart';
import '../routes/file_transfer.dart';
import '../routes/routes.dart';
import '../utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _isConnected;
  bool? _isWiFiAPEnabled;
  bool _permissionGranted = false;
  bool _serverStarted = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (Platform.isAndroid) {
      final granted = await _requestPermissions();
      if (mounted) {
        setState(() {
          _permissionGranted = granted;
        });
      }
      await _getWifiState();
    } else {
      // For non-Android platforms, permissions are handled differently
      if (mounted) {
        setState(() {
          _permissionGranted = true;
        });
      }
      await _getWifiState();
    }
    
    // Start server once after permissions are granted
    _startServerIfNeeded();
  }

  void _startServerIfNeeded() {
    if (_serverStarted) return;
    _serverStarted = true;

    final transferProvider = Provider.of<FileTransferProvider>(context, listen: false);

    FileTransfer.instance.startServer(
      onEndpointRegistered: (endpoint) {
        FileTransfer.instance.connectedEndpoints.add(endpoint);
        Routes.toTransfer();
      },
      onFileReceived: (File receivedFile) {
        // Handle received file - could show notification
      },
      provider: transferProvider,
    );
  }

  Future<void> _getWifiState() async {
    if (Platform.isAndroid) {
      final conw = await WifiManager.isAndroidConnectedToWifi();
      final accn = await WifiManager.isAndroidWiFiAccessPointEnabled();

      if (mounted) {
        setState(() {
          _isConnected = conw;
          _isWiFiAPEnabled = accn;
        });
      }
    } else if (Platform.isLinux) {
      final cow = HotspotManager.instance.isLinuxConnectedToWiFi();
      final accn = await HotspotManager.instance.isLinuxAccessPointEnabled();

      if (mounted) {
        setState(() {
          _isConnected = cow;
          _isWiFiAPEnabled = accn;
        });
      }
    } else {
      // For other platforms, assume connected
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isWiFiAPEnabled = false;
        });
      }
    }
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.camera,
    ];

    final int androidSdkVersion = await getAndroidSDkVersion();

    if (androidSdkVersion < 33) {
      // Android 12 and below - use legacy storage permission
      permissions.add(Permission.storage);
    } else {
      // Android 13+ - use granular media permissions
      permissions.addAll([
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ]);
    }

    if (await _checkPermissions(permissions)) return true;

    final statuses = await permissions.request();
    
    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    // If any permission is permanently denied, open app settings
    if (!allGranted) {
      final hasPermanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      if (hasPermanentlyDenied) {
        await openAppSettings();
      }
    }
    
    return allGranted;
  }

  Future<bool> _checkPermissions(List<Permission> permissions) async {
    for (var element in permissions) {
      if (!(await element.isGranted)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Show permission request screen on Android if not granted
    if (Platform.isAndroid && !_permissionGranted) {
      return GetPermission(
        onRequest: () async {
          final granted = await _requestPermissions();
          if (mounted) {
            setState(() {
              _permissionGranted = granted;
            });
          }
        },
      );
    }

    // Show loading while getting WiFi state
    if (_isWiFiAPEnabled == null || _isConnected == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: const Text("ZTransfer"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: _isConnected == true ? 'Connected' : 'Disconnected',
              child: Icon(
                _isConnected == true ? Icons.wifi : Icons.wifi_off,
                color: _isConnected == true ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_tethering,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "A WiFi File Transfer App",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              "Transfer files over WiFi",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 40),
            _buildActionButton(
              context,
              icon: Icons.download,
              label: 'Receive',
              onPressed: _handleReceive,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              icon: Icons.upload,
              label: 'Send',
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _handleReceive() {
    if (Platform.isAndroid) {
      showDiscoveryChoiceDialog(context).then((choice) {
        if (choice == Choice.qrCode) {
          Routes.toScanner();
        } else if (choice == Choice.networkDiscovery) {
          QR.toName(Routes.analyis);
        }
      });
    } else {
      Routes.toEnterEndPoint();
    }
  }

  void _handleSend() {
    if (Platform.isAndroid || Platform.isLinux) {
      if (_isWiFiAPEnabled == null || _isConnected == null) {
        showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (_) => const Wrap(
            children: [PeerConnectionSetupPage(nextDest: Routes.display)],
          ),
        );
      } else {
        Routes.toDisplayQR();
      }
    } else {
      Routes.toDisplayQR();
    }
  }
}

class GetPermission extends StatelessWidget {
  final VoidCallback onRequest;
  const GetPermission({super.key, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                "Permissions Required",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "ZTransfer needs access to storage, camera, and location to work properly.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.check),
                label: const Text('Grant Access'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnableWifiWidget extends StatelessWidget {
  final VoidCallback onRequest;
  final String message;
  const EnableWifiWidget({
    super.key,
    required this.onRequest,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.wifi),
                label: const Text('Enable'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Choice?> showDiscoveryChoiceDialog(BuildContext context) async {
  return showDialog<Choice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Connect Device'),
      content: const Text('How would you like to connect your device?'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, Choice.qrCode),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, Choice.networkDiscovery),
          icon: const Icon(Icons.wifi_find),
          label: const Text('Network Discovery'),
        ),
      ],
    ),
  );
}

enum Choice { qrCode, networkDiscovery }
