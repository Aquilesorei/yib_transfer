import 'package:flutter/material.dart';
import 'package:yifi/models/DeviceInfo.dart';
import 'package:yifi/yifi.dart';

class NetworkAnalysisWidget extends StatefulWidget {
  const NetworkAnalysisWidget({Key? key}) : super(key: key);

  @override
  State<NetworkAnalysisWidget> createState() => _NetworkAnalysisWidgetState();
}

class _NetworkAnalysisWidgetState extends State<NetworkAnalysisWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<DeviceInfo> _devices = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
      setState(() {}); // Trigger a rebuild for animation updates
    });
    startAnalysis();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _animationController.repeat();
    try {
      _devices = await Yifi.getConnectedDevices();
      _animationController.forward(from: 0.5); // Complete animation on success
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: _isLoading,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SizedBox(
                    width: 100 * _animationController.value,
                    height: 100 * _animationController.value,
                    child: CircularProgressIndicator(
                      value: _animationController.value,
                      strokeWidth: 10,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Text("Analyzing network...")
            else if (_devices.isNotEmpty)
              Column(
                children: [
                  const Text("Discovered devices"),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          title: Text(device.deviceName),
                          subtitle: Text(device.ipAddress),
                        );
                      },
                    ),
                  ),
                ],
              )
            else if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red))
              else
                const Text("No devices found",style: TextStyle(fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }
}
