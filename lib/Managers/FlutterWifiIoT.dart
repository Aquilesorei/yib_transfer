// ignore_for_file: deprecated_member_use, package_api_docs, public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';

const String STA_DEFAULT_SSID = "STA_SSID";
const String STA_DEFAULT_PASSWORD = "STA_PASSWORD";
const NetworkSecurity STA_DEFAULT_SECURITY = NetworkSecurity.WPA;

const String AP_DEFAULT_SSID = "AP_SSID";
const String AP_DEFAULT_PASSWORD = "AP_PASSWORD";


class FlutterWifiIoT extends StatefulWidget {
  const FlutterWifiIoT({super.key});

  @override
  State<FlutterWifiIoT> createState() => _FlutterWifiIoTState();
}

class _FlutterWifiIoTState extends State<FlutterWifiIoT> {
  String? _sPreviousAPSSID = "";
  String? _sPreviousPreSharedKey = "";

  List<WifiNetwork?>? _htResultNetwork;
  final Map<String, bool> _htIsNetworkRegistered = {};

  bool _isEnabled = false;
  bool _isConnected = false;
  bool _isWiFiAPEnabled = false;
  bool _isWiFiAPSSIDHidden = false;
  bool _isWifiAPSupported = true;
  bool _isWifiEnableOpenSettings = false;
  bool _isWifiDisableOpenSettings = false;

  final TextStyle textStyle = const TextStyle(color: Colors.white);

  @override
  initState() {
    WiFiForIoTPlugin.isEnabled().then((val) {
      _isEnabled = val;
    });

    WiFiForIoTPlugin.isConnected().then((val) {
      _isConnected = val;
    });

    WiFiForIoTPlugin.isWiFiAPEnabled().then((val) {
      _isWiFiAPEnabled = val;
    }).catchError((val) {
      _isWifiAPSupported = false;
    });

    super.initState();
  }

  storeAndConnect(String psSSID, String psKey) async {
    await storeAPInfos();
    await WiFiForIoTPlugin.setWiFiAPSSID(psSSID);
    await WiFiForIoTPlugin.setWiFiAPPreSharedKey(psKey);
  }

  storeAPInfos() async {
    String? sAPSSID;
    String? sPreSharedKey;

    try {
      sAPSSID = await WiFiForIoTPlugin.getWiFiAPSSID();
    } on PlatformException {
      sAPSSID = "";
    }

    try {
      sPreSharedKey = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    } on PlatformException {
      sPreSharedKey = "";
    }

    setState(() {
      _sPreviousAPSSID = sAPSSID;
      _sPreviousPreSharedKey = sPreSharedKey;
    });
  }

  restoreAPInfos() async {
    WiFiForIoTPlugin.setWiFiAPSSID(_sPreviousAPSSID!);
    WiFiForIoTPlugin.setWiFiAPPreSharedKey(_sPreviousPreSharedKey!);
  }

  // [sAPSSID, sPreSharedKey]
  Future<List<String>> getWiFiAPInfos() async {
    String? sAPSSID;
    String? sPreSharedKey;

    try {
      sAPSSID = await WiFiForIoTPlugin.getWiFiAPSSID();
    } on Exception {
      sAPSSID = "";
    }

    try {
      sPreSharedKey = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    } on Exception {
      sPreSharedKey = "";
    }

    return [sAPSSID!, sPreSharedKey!];
  }

  Future<WIFI_AP_STATE?> getWiFiAPState() async {
    int? iWiFiState;

    WIFI_AP_STATE? wifiAPState;

    try {
      iWiFiState = await WiFiForIoTPlugin.getWiFiAPState();
    } on Exception {
      iWiFiState = WIFI_AP_STATE.WIFI_AP_STATE_FAILED.index;
    }

    if (iWiFiState == WIFI_AP_STATE.WIFI_AP_STATE_DISABLING.index) {
      wifiAPState = WIFI_AP_STATE.WIFI_AP_STATE_DISABLING;
    } else if (iWiFiState == WIFI_AP_STATE.WIFI_AP_STATE_DISABLED.index) {
      wifiAPState = WIFI_AP_STATE.WIFI_AP_STATE_DISABLED;
    } else if (iWiFiState == WIFI_AP_STATE.WIFI_AP_STATE_ENABLING.index) {
      wifiAPState = WIFI_AP_STATE.WIFI_AP_STATE_ENABLING;
    } else if (iWiFiState == WIFI_AP_STATE.WIFI_AP_STATE_ENABLED.index) {
      wifiAPState = WIFI_AP_STATE.WIFI_AP_STATE_ENABLED;
    } else if (iWiFiState == WIFI_AP_STATE.WIFI_AP_STATE_FAILED.index) {
      wifiAPState = WIFI_AP_STATE.WIFI_AP_STATE_FAILED;
    }

    return wifiAPState!;
  }

  Future<List<APClient>> getClientList(
      bool onlyReachables, int reachableTimeout) async {
    List<APClient> htResultClient;

    try {
      htResultClient = await WiFiForIoTPlugin.getClientList(
          onlyReachables, reachableTimeout);
    } on PlatformException {
      htResultClient = <APClient>[];
    }

    return htResultClient;
  }

  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = <WifiNetwork>[];
    }

    return htResultNetwork;
  }

  isRegisteredWifiNetwork(String ssid) async {
    bool bIsRegistered;

    try {
      bIsRegistered = await WiFiForIoTPlugin.isRegisteredWifiNetwork(ssid);
    } on PlatformException {
      bIsRegistered = false;
    }

    setState(() {
      _htIsNetworkRegistered[ssid] = bIsRegistered;
    });
  }

  void showClientList() async {
    /// Refresh the list and show in console
    getClientList(false, 300).then((val) => val.forEach((oClient) {
      print("************************");
      print("Client :");
      print("ipAddr = '${oClient.ipAddr}'");
      print("hwAddr = '${oClient.hwAddr}'");
      print("device = '${oClient.device}'");
      print("isReachable = '${oClient.isReachable}'");
      print("************************");
    }));
  }

  Widget getWidgets() {
    WiFiForIoTPlugin.isConnected().then((val) {
      setState(() {
        _isConnected = val;
      });
    });

    // disable scanning for ios as not supported
    if (_isConnected) {
      _htResultNetwork = null;
    }

    if (_htResultNetwork != null && _htResultNetwork!.isNotEmpty) {
      final List<ListTile> htNetworks = <ListTile>[];

      for (var oNetwork in _htResultNetwork!) {
        final PopupCommand oCmdConnect =
        PopupCommand("Connect", oNetwork!.ssid!);
        final PopupCommand oCmdRemove = PopupCommand("Remove", oNetwork.ssid!);

        final List<PopupMenuItem<PopupCommand>> htPopupMenuItems = [];

        htPopupMenuItems.add(
          PopupMenuItem<PopupCommand>(
            value: oCmdConnect,
            child: const Text('Connect'),
          ),
        );

        setState(() {
          isRegisteredWifiNetwork(oNetwork.ssid!);
          if (_htIsNetworkRegistered.containsKey(oNetwork.ssid) &&
              _htIsNetworkRegistered[oNetwork.ssid]!) {
            htPopupMenuItems.add(
              PopupMenuItem<PopupCommand>(
                value: oCmdRemove,
                child: const Text('Remove'),
              ),
            );
          }

          htNetworks.add(
            ListTile(
              title: Text("${oNetwork.ssid!}${(_htIsNetworkRegistered.containsKey(oNetwork.ssid) &&
                      _htIsNetworkRegistered[oNetwork.ssid]!)
                      ? " *"
                      : ""}"),
              trailing: PopupMenuButton<PopupCommand>(
                padding: EdgeInsets.zero,
                onSelected: (PopupCommand poCommand) {
                  switch (poCommand.command) {
                    case "Connect":
                      WiFiForIoTPlugin.connect(STA_DEFAULT_SSID,
                          password: STA_DEFAULT_PASSWORD,
                          joinOnce: true,
                          security: STA_DEFAULT_SECURITY);
                      break;
                    case "Remove":
                      WiFiForIoTPlugin.removeWifiNetwork(poCommand.argument);
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => htPopupMenuItems,
              ),
            ),
          );
        });
      }

      return ListView(
        padding: kMaterialListPadding,
        children: htNetworks,
      );
    } else {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: getButtonWidgetsForAndroid(),
          ),
        ),
      );
    }
  }

  List<Widget> getButtonWidgetsForAndroid() {
    final List<Widget> htPrimaryWidgets = <Widget>[];

    WiFiForIoTPlugin.isEnabled().then((val) {
      setState(() {
        _isEnabled = val;
      });
    });

    // wifi enabled
    if (_isEnabled) {
      htPrimaryWidgets.addAll([
        const SizedBox(height: 10),
        const Text("Wifi Enabled"),
        MaterialButton(
          color: Colors.blue,
          child: Text("Disable", style: textStyle),
          onPressed: () {
            WiFiForIoTPlugin.setEnabled(false,
                shouldOpenSettings: _isWifiDisableOpenSettings);
          },
        ),
      ]);

      WiFiForIoTPlugin.isConnected().then((val) {
        setState(() {
          _isConnected = val;
        });
      });
      // wifi enabled  and user is connected to a wifi
      if (_isConnected) {
        htPrimaryWidgets.addAll(<Widget>[
          const Text("Connected"),
          FutureBuilder(
              future: WiFiForIoTPlugin.getSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String?> ssid) {
                return Text("SSID: ${ssid.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getBSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String?> bssid) {
                return Text("BSSID: ${bssid.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getCurrentSignalStrength(),
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int?> signal) {
                return Text("Signal: ${signal.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getFrequency(),
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int?> freq) {
                return Text("Frequency : ${freq.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getIP(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String?> ip) {
                return Text("IP : ${ip.data}");
              }),
          MaterialButton(
            color: Colors.blue,
            child: Text("Disconnect", style: textStyle),
            onPressed: () {
              WiFiForIoTPlugin.disconnect();
            },
          ),
          CheckboxListTile(
              title: const Text("Disable WiFi on settings"),
              subtitle: const Text("Available only on android API level >= 29"),
              value: _isWifiDisableOpenSettings,
              onChanged: (bool? setting) {
                if (setting != null) {
                  setState(() {
                    _isWifiDisableOpenSettings = setting;
                  });
                }
              })
        ]);
      }

      // wifi enabled  and user is disconnected
      else {
        htPrimaryWidgets.addAll(<Widget>[
          const Text("Disconnected"),
          MaterialButton(
            color: Colors.blue,
            child: Text("Scan", style: textStyle),
            onPressed: () async {
              _htResultNetwork = await loadWifiList();
              setState(() {});
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MaterialButton(
                color: Colors.blue,
                child: Text("Use WiFi", style: textStyle),
                onPressed: () {
                  WiFiForIoTPlugin.forceWifiUsage(true);
                },
              ),
              const SizedBox(width: 50),
              MaterialButton(
                color: Colors.blue,
                child: Text("Use 3G/4G", style: textStyle),
                onPressed: () {
                  WiFiForIoTPlugin.forceWifiUsage(false);
                },
              ),
            ],
          ),
          CheckboxListTile(
              title: const Text("Disable WiFi on settings"),
              subtitle: const Text("Available only on android API level >= 29"),
              value: _isWifiDisableOpenSettings,
              onChanged: (bool? setting) {
                if (setting != null) {
                  setState(() {
                    _isWifiDisableOpenSettings = setting;
                  });
                }
              })
        ]);
      }
    }
    // wifi  disabled
    else {
      htPrimaryWidgets.addAll(<Widget>[
        const SizedBox(height: 10),
        const Text("Wifi Disabled"),
        MaterialButton(
          color: Colors.blue,
          child: Text("Enable", style: textStyle),
          onPressed: () {
            setState(() {
              WiFiForIoTPlugin.setEnabled(true,
                  shouldOpenSettings: _isWifiEnableOpenSettings);
            });
          },
        ),
        CheckboxListTile(
            title: const Text("Enable WiFi on settings"),
            subtitle: const Text("Available only on android API level >= 29"),
            value: _isWifiEnableOpenSettings,
            onChanged: (bool? setting) {
              if (setting != null) {
                setState(() {
                  _isWifiEnableOpenSettings = setting;
                });
              }
            })
      ]);
    }

    htPrimaryWidgets.add(const Divider(
      height: 32.0,
    ));

    // device support hotspot
    if (_isWifiAPSupported) {
      htPrimaryWidgets.addAll(<Widget>[
        const Text("WiFi AP State"),
        FutureBuilder(
            future: getWiFiAPState(),
            initialData: WIFI_AP_STATE.WIFI_AP_STATE_DISABLED,
            builder: (BuildContext context,
                AsyncSnapshot<WIFI_AP_STATE?> wifiState) {
              final List<Widget> widgets = [];

              if (wifiState.data == WIFI_AP_STATE.WIFI_AP_STATE_ENABLED) {
                widgets.add(MaterialButton(
                  color: Colors.blue,
                  child: Text("Get Client List", style: textStyle),
                  onPressed: () {
                    showClientList();
                  },
                ));
              }

              widgets.add(Text(wifiState.data.toString()));

              return Column(children: widgets);
            }),
      ]);

      WiFiForIoTPlugin.isWiFiAPEnabled()
          .then((val) => setState(() {
        _isWiFiAPEnabled = val;
      }))
          .catchError((val) {
        _isWiFiAPEnabled = false;
      });

      // hotspot is enabled
      if (_isWiFiAPEnabled) {
        htPrimaryWidgets.addAll(<Widget>[
          const Text("Wifi AP Enabled"),
          MaterialButton(
            color: Colors.blue,
            child: Text("Disable", style: textStyle),
            onPressed: () {
              WiFiForIoTPlugin.setWiFiAPEnabled(false);
            },
          ),
        ]);
      }
      // hotspot  is disabled
      else {
        htPrimaryWidgets.addAll(<Widget>[
          const Text("Wifi AP Disabled"),
          MaterialButton(
            color: Colors.blue,
            child: Text("Enable", style: textStyle),
            onPressed: () {
              WiFiForIoTPlugin.setWiFiAPEnabled(true);
            },
          ),
        ]);
      }

      WiFiForIoTPlugin.isWiFiAPSSIDHidden()
          .then((val) => setState(() {
        _isWiFiAPSSIDHidden = val;
      }))
          .catchError((val) => _isWiFiAPSSIDHidden = false);
      if (_isWiFiAPSSIDHidden) {
        htPrimaryWidgets.add(const Text("SSID is hidden"));
        !_isWiFiAPEnabled
            ? MaterialButton(
          color: Colors.blue,
          child: Text("Show", style: textStyle),
          onPressed: () {
            WiFiForIoTPlugin.setWiFiAPSSIDHidden(false);
          },
        )
            : const SizedBox(width: 0, height: 0);
      } else {
        htPrimaryWidgets.add(const Text("SSID is visible"));
        !_isWiFiAPEnabled
            ? MaterialButton(
          color: Colors.blue,
          child: Text("Hide", style: textStyle),
          onPressed: () {
            WiFiForIoTPlugin.setWiFiAPSSIDHidden(true);
          },
        )
            : const SizedBox(width: 0, height: 0);
      }

      FutureBuilder(
          future: getWiFiAPInfos(),
          initialData: const <String>[],
          builder: (BuildContext context, AsyncSnapshot<List<String>> info) {
            htPrimaryWidgets.addAll(<Widget>[
              Text("SSID : ${info.data![0]}"),
              Text("KEY  : ${info.data![1]}"),
              MaterialButton(
                color: Colors.blue,
                child: Text(
                    "Set AP info ($AP_DEFAULT_SSID/$AP_DEFAULT_PASSWORD)",
                    style: textStyle),
                onPressed: () {
                  storeAndConnect(AP_DEFAULT_SSID, AP_DEFAULT_PASSWORD);
                },
              ),
              Text("AP SSID stored : $_sPreviousAPSSID"),
              Text("KEY stored : $_sPreviousPreSharedKey"),
              MaterialButton(
                color: Colors.blue,
                child: Text("Store AP infos", style: textStyle),
                onPressed: () {
                  storeAPInfos();
                },
              ),
              MaterialButton(
                color: Colors.blue,
                child: Text("Restore AP infos", style: textStyle),
                onPressed: () {
                  restoreAPInfos();
                },
              ),
            ]);

            return Text("SSID : ${info.data![0]}");
          });
    } else {
      htPrimaryWidgets.add(
          const Center(child: Text("Wifi AP probably not supported by your device")));
    }

    return htPrimaryWidgets;
  }


  @override
  Widget build(BuildContext poContext) {
    return MaterialApp(
      title: "WifiFlutter Example Android",
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WifiFlutter Example Android'),
          actions: _isConnected
              ? <Widget>[
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case "disconnect":
                    WiFiForIoTPlugin.disconnect();
                    break;
                  case "remove":
                    WiFiForIoTPlugin.getSSID().then((val) =>
                        WiFiForIoTPlugin.removeWifiNetwork(val!));
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) =>
              <PopupMenuItem<String>>[
                const PopupMenuItem<String>(
                  value: "disconnect",
                  child: Text('Disconnect'),
                ),
                const PopupMenuItem<String>(
                  value: "remove",
                  child: Text('Remove'),
                ),
              ],
            ),
          ]
              : null,
        ),
        body: getWidgets(),
      ),
    );
  }
}

class PopupCommand {
  String command;
  String argument;

  PopupCommand(this.command, this.argument);
}