import 'package:flutter/material.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:yifi/yifi.dart';

import '../Managers/HotspotManager.dart';
import '../Managers/WifiManager.dart';
import '../routes/routes.dart';
import 'dart:io';
class PeerConnectionSetupPage extends StatefulWidget {
  final String nextDest;
  const PeerConnectionSetupPage({super.key, required this.nextDest});

  @override
  State<PeerConnectionSetupPage> createState() => _PeerConnectionSetupPageState();
}

class _PeerConnectionSetupPageState extends State<PeerConnectionSetupPage> {
  String connectionStatus = '';



  bool _scan = true;


  Future<void> _startConnectionCheck() async {
    while (_scan && mounted) {
      if(Platform.isAndroid) {
        bool wifiConnection =  await WifiManager.isAndroidConnectedToWifi();
        bool wifiAPEnabled = await WifiManager.isAndroidWiFiAccessPointEnabled();


        if (wifiAPEnabled || wifiConnection) {
          QR.toName(widget.nextDest);
          _scan = false;
        }
      }else if(Platform.isLinux){

        final cow = HotspotManager.instance.isLinuxConnectedToWiFi();
        final accn =  await HotspotManager.instance.isLinuxAccessPointEnabled();

        if (cow|| accn) {


         QR.toName(widget.nextDest);
            _scan = false;

        }
      }


      await Future.delayed(const Duration(seconds: 1));

    }
  }



  Future<void> _enableHotSpot() async {
    if(Platform.isAndroid) {
      await Yifi.promptUserToEnableHotspot();
    } else if(Platform.isLinux){

      Routes.toHotSpotCodeQr();
    }
  }

  Future<void> _connectToWiFi() async {
    if(Platform.isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
    } else if(Platform.isLinux){
      Routes.toWifiScanner();
    }
  }


  @override
  void initState(){
    _startConnectionCheck();
    super.initState();

  }

  @override
  void dispose(){
    _scan = false;
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Peer Connection Status:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              connectionStatus,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _enableHotSpot,
                child: const Text('Activate Hotspot'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _connectToWiFi,
                child: const Text('Connect to WiFi'),
              ),
            ),
          ],
        ),
      );
  }
}