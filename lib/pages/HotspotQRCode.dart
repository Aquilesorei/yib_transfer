import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yib_transfer/Managers/HotspotManager.dart';


class HotspotQRCode extends StatefulWidget {
  const HotspotQRCode({super.key});

  @override
  State<HotspotQRCode> createState() => _HotspotQRCodeState();
}

class _HotspotQRCodeState extends State<HotspotQRCode> {
  final String hotspotSSID = HotspotManager.instance.configValues!.ssid;
 final String hotspotPassword = HotspotManager.instance.configValues!.pass;
  bool hotspotStarted = false;


  @override
  void initState() {
    super.initState();
    startHotspot();
  }

  Future<void> startHotspot() async {
    try {

       await HotspotManager.instance.startHotspot(onProcess: (Process pro) async {
         await HotspotManager.instance.isLinuxAccessPointEnabled();
         setState(() {
           hotspotStarted = true;
         });
       });


    } catch (e) {
      print('Error starting hotspot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Hotspot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!hotspotStarted)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            if (hotspotStarted)
              SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("""
                    Please connect to this network
                    """),
                    QrImageView(
                      data: 'WIFI:T:WPA;S:$hotspotSSID;P:$hotspotPassword;;',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text('SSID: $hotspotSSID'),
                    Text('Password: $hotspotPassword'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
