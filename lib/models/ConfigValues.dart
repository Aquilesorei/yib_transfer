
import 'dart:convert';
import 'dart:io';

class ConfigValues {
  String ssid;
  String pass;
  String ifaceWifi;
  String ifaceInet;


  ConfigValues({
    required this.ssid,
    required this.pass,
    required this.ifaceWifi,
    this.ifaceInet ="lo",
  });

  // Convert the object to a Map for JSON serialization
  Map<String, dynamic> toJsonMap() {
    return {
      'ssid': ssid,
      'pass': pass,
      'iface_wifi': ifaceWifi,
      'iface_inet': ifaceInet,
    };
  }

  // Create a ConfigValues object from a Map
  factory ConfigValues.fromJsonMap(Map<String, dynamic> map) {
    return ConfigValues(
      ssid: map['ssid'],
      pass: map['pass'],
      ifaceWifi: map['iface_wifi'],
      ifaceInet: map['iface_inet'],
    );
  }

  // Serialize the object to a JSON string
  String toJsonString() {
    Map<String, dynamic> jsonMap = toJsonMap();
    return jsonEncode(jsonMap);
  }

  // Create a ConfigValues object from a JSON string
  factory ConfigValues.fromJsonString(String jsonString) {
    Map<String, dynamic> parsedJson = jsonDecode(jsonString);
    return ConfigValues.fromJsonMap(parsedJson);
  }



  // Load configuration values from a .conf file
  static Future<ConfigValues?> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final jsonMap = jsonDecode(contents);
      return ConfigValues.fromJsonMap(jsonMap);
    } catch (e) {
      print('Error loading configuration from file: $e');
      return null;
    }
  }

  // Save configuration values to a .conf file
  Future<void> saveToFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(toJsonString());
    } catch (e) {
      print('Error saving configuration to file: $e');
    }
  }
}

