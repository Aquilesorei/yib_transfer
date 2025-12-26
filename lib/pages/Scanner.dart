import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ztransfer/routes/file_transfer.dart';

import '../components/AppDrawer.dart';
import '../models/PeerEndpoint.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<StatefulWidget> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? _scannedCode;
  bool _scanned = false;
  bool _registering = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_scanned || _registering) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _scannedCode = code;
    });

    if (isValidEnPoint(code)) {
      setState(() {
        _scanned = true;
        _registering = true;
      });

      FileTransfer.instance.connectedEndpoints.add(PeerEndpoint.parse(code));

      FileTransfer.instance
          .register(FileTransfer.instance.connectedEndpoints.last)
          .then((success) {
        if (!mounted) return;

        setState(() {
          _registering = false;
        });

        final snackBar = SnackBar(
          content: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  success ? Icons.done : Icons.cancel,
                  color: success ? Colors.blue : Colors.red,
                ),
              ),
              Text(success
                  ? "Successfully registered!"
                  : "Failed to register!"),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registering) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Registering..."),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          // Flash toggle
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {
                _torchOn = !_torchOn;
              });
            },
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Camera error: ${error.errorCode.name}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Scanner overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_scannedCode != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _scannedCode!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    const Text(
                      'Point camera at QR code',
                      style: TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.stop(),
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _scanned = false;
                            _scannedCode = null;
                          });
                          _controller.start();
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}