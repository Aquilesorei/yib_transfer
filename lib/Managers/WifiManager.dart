

import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';



class WifiManager{



static Future<bool> isAndroidWifiEnabled() =>  WiFiForIoTPlugin.isEnabled();

static  Future<bool> isAndroidConnectedToWifi() => WiFiForIoTPlugin.isConnected();

static  Future<bool> isAndroidWiFiAccessPointEnabled() =>  WiFiForIoTPlugin.isWiFiAPEnabled();



 static Future<List<APClient>> getClientList(bool onlyReachables, int reachableTimeout) async {
  List<APClient> htResultClient;

  try {
    htResultClient = await WiFiForIoTPlugin.getClientList(
        onlyReachables, reachableTimeout);
  } on PlatformException {
    htResultClient = <APClient>[];
  }

  return htResultClient;
}







}