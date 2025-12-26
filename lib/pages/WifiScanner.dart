import 'package:flutter/material.dart';
import 'package:ztransfer/components/PasswordTextField.dart';

import '../Managers/HotspotManager.dart';

class WifiScanner extends StatefulWidget {
  const WifiScanner({super.key});

  @override
  State<WifiScanner> createState() => _WifiScannerState();
}

class _WifiScannerState extends State<WifiScanner> {
  List<String> wifiList = [];
  List<String> protectedWifiList = [];

  bool isScanning = false;
  bool connected = false;
  final passwordController =
      TextEditingController(); // Initialize an empty password variable

  @override
  void initState() {
    super.initState();
    scanForNetworks();
  }

  Future<void> scanForNetworks() async {
    setState(() {
      isScanning = true;
    });
    wifiList = await HotspotManager.instance.listWifiNetworks();
    protectedWifiList =
        await HotspotManager.instance.listPasswordProtectedWiFiNetworks();
    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ListTile(
          leading: Icon(
            Icons.signal_wifi_4_bar_outlined,
          ),
          title: Text('Wifi networks'),
          subtitle:
              Text('Select a network', style: TextStyle(color: Colors.grey)),
        ),
      ),
      body: isScanning
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: CircularProgressIndicator()),
                Center(
                    child: Text(
                  "Scanning..",
                  style: TextStyle(color: Colors.grey),
                )),
              ],
            )
          : ListView.builder(
              itemCount: wifiList.length,
              itemBuilder: (context, index) {
                final wifi = wifiList[index];
                final protected = protectedWifiList.contains(wifi);
                return ListTile(
                  title: Text(wifi),
                  leading: Icon(protected
                      ? Icons.wifi_lock
                      : Icons.signal_wifi_4_bar_outlined
                  ),
                  onTap: () async {
                    if (protected) {
                      _showPasswordDialog(context, wifi);

                    } else {
                      bool success = await HotspotManager.instance.connectToWifi(wifi,null);
                      setState(() {
                        connected = success;
                      });
                    }
                  },
                );
              },
            ),
    );
  }

  void onConnectClicked(BuildContext context, String ssid) async {
    String password = passwordController.text;


    bool success = await HotspotManager.instance.connectToWifi(
      ssid,
      password,
    );

    setState(() {
      connected = success;
    });
   // print(success);
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    String ssid,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible:
          false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: Container(
            padding: const EdgeInsets.all(20.0),
            child: PasswordTextField(
              controller: passwordController,
              labelText: "password",
              hintText: "enter the password",
              obscure: true,
              onSubmitted: (_) => onConnectClicked(context, ssid),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => onConnectClicked(context, ssid),
              child: const Text('connect'),
            ),
          ],
        );
      },
    );
  }
}
