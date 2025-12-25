import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yifi/models.dart';
import 'package:yifi/yifi.dart';

class NetworkAnalysisWidget extends StatefulWidget {
  const NetworkAnalysisWidget({super.key});

  @override
  State<NetworkAnalysisWidget> createState() => _NetworkAnalysisWidgetState();
}

class _NetworkAnalysisWidgetState extends State<NetworkAnalysisWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<DeviceItem> _devices = [];
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
      final devicesJson = await Yifi.getConnectedDevices();
      if (devicesJson != null && devicesJson.isNotEmpty) {
        // Parse JSON string to list of DeviceItem
        final List<dynamic> jsonList = jsonDecode(devicesJson);
        _devices = jsonList
            .map((json) => DeviceItem.fromJsonMap(json as Map<String, dynamic>))
            .toList();
      }
      _animationController.forward(from: 0.5); // Complete animation on success
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Analysis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : startAnalysis,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SizedBox(
                  width: 100 * _animationController.value.clamp(0.3, 1.0),
                  height: 100 * _animationController.value.clamp(0.3, 1.0),
                  child: CircularProgressIndicator(
                    value: _animationController.value,
                    strokeWidth: 6,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text("Analyzing network..."),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: startAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_other, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No devices found",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Make sure you're connected to a network",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: startAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Found ${_devices.length} device${_devices.length > 1 ? 's' : ''}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.devices),
                  ),
                  title: Text(device.deviceName),
                  subtitle: Text(device.ipAddress),
                  trailing: Text(
                    device.vendorName,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
