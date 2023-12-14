import 'dart:io';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:yib_transfer/Managers/HotspotManager.dart';
import 'package:yib_transfer/Managers/WifiManager.dart';
import 'package:yib_transfer/Providers/FileTransferProvider.dart';
import 'package:yib_transfer/constants.dart';
import 'package:yib_transfer/pages/PeerConnectionSetupPage.dart';
import 'package:yifi/yifi.dart';

import '../components/AppDrawer.dart';
import '../models/PeerEndpoint.dart';
import '../routes/FileTransfert.dart';
import '../routes/routes.dart';
import '../utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _isConnected;
  bool? _isWiFiAPEnabled;

  bool permissionGranted = false;
  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      _requestPermissions().then((bool granted) {
        setState(() {
          permissionGranted = granted;
        });
        /*   if(!granted) {
          InstalledApps.openSettings(packageName);
        }*/
      });

      getWifiState();
    }
  }

  Future<void> getWifiState() async {
    if (Platform.isAndroid) {
      final conw = await WifiManager.isAndroidConnectedToWifi();
      final accn = await WifiManager.isAndroidWiFiAccessPointEnabled();

      setState(() {
        _isConnected = conw;
        _isWiFiAPEnabled = accn;
      });
    } else if (Platform.isLinux) {
      final cow = HotspotManager.instance.isLinuxConnectedToWiFi();
      final accn = await HotspotManager.instance.isLinuxAccessPointEnabled();

      setState(() {
        _isConnected = cow;
        _isWiFiAPEnabled = accn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {

      if (!permissionGranted) {
        return GetPermission(onRequest: _requestPermissions);
      }
    }

    final transferProvider = Provider.of<FileTransferProvider>(context);

    FileTransfer.instance.startServer(
        onEndpointRegistered: (endpoint) {
          FileTransfer.instance.connectedEndpoints.add(endpoint);
          Routes.toTransfer();
        },
        onFileReceived: (File receivedFile) {},
        provider: transferProvider);
    return Scaffold(
      drawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: const Text('Yib\'s Transfer'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "A File transfer  App by Yibloa",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    if ((_isWiFiAPEnabled == null )|| (_isConnected == null)) {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (_) => Wrap(children: [
                          PeerConnectionSetupPage(
                              nextDest: Platform.isAndroid
                                  ? Routes.scan
                                  : Routes.enterEndpoint)
                        ]),
                      );
                    } else {
                      Routes.toScanner();
                    }
                  } else {
                    Routes.toEnterEndPoint();
                  }
                },
                child: const Text('Receive'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  if (Platform.isAndroid || Platform.isLinux) {
                    if ((_isWiFiAPEnabled == null )|| (_isConnected == null)) {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (_) => const Wrap(children: [
                          PeerConnectionSetupPage(nextDest: Routes.display)
                        ]),
                      );
                    } else {
                      Routes.toDisplayQR();
                    }
                  } else {
                    Routes.toDisplayQR();
                  }
                },
                child: const Text('Send'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
    ];

    final int? androidVersion = await Yifi.getPlatformVersion();

    if (androidVersion == null) return false;

    if (androidVersion < 13) {
      permissions.add(Permission.storage);
    } else {
      permissions.add(Permission.manageExternalStorage);
    }

    if ((await checkPermissions(permissions))) return true;

    final statuses = await permissions.request();

    return statuses.values.every((status) => status.isGranted);
  }
}

Future<bool> checkPermissions(List<Permission> permissions) async {
  for (var element in permissions) {
    if (!(await element.isGranted)) {
      return false;
    }
  }
  return true;
}

class GetPermission extends StatelessWidget {
  final void Function() onRequest;
  const GetPermission({super.key, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                """
           You have to allow access to storage ,camera and location """,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
                onPressed: onRequest, child: const Text('Grant access')),
          ],
        ),
      ),
    );
  }
}

class EnableWifiWidget extends StatelessWidget {
  final void Function() onRequest;
  final String message;
  const EnableWifiWidget(
      {super.key, required this.onRequest, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(onPressed: onRequest, child: const Text('Enable')),
          ],
        ),
      ),
    );
  }
}
