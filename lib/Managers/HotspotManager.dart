


import 'dart:io';
import 'dart:math';

import '../models/ConfigValues.dart';
import 'package:process_run/shell.dart';

class HotspotManager {
  static const configFilename = "yi.bloa";
  ConfigValues?  configValues;


  static HotspotManager? _instance;

 static HotspotManager get instance {
    _instance ??= HotspotManager._();
    return _instance!;
  }



  HotspotManager._();

  static  Future<void> initConfig() async {
    if(Platform.isLinux || Platform.isWindows){
      final file = File(configFilename);
      if(!file.existsSync()){
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: true);

        NetworkInterface interface = interfaces.firstWhere((element) => element.name.startsWith("wl"));


        instance.configValues = ConfigValues(
            ssid: generateStringWithPrefix() ,
            pass: generateSecurePassword(),
            ifaceWifi: interface.name
        );

       await instance.configValues!.saveToFile(configFilename);


      }
      else {

           instance.configValues =  await ConfigValues.loadFromFile(configFilename);
        }
    }
  }





  Future<List<String>> listWifiNetworks() async {
    await enableWifi();
    try {
      final result = await Process.run('nmcli', ['-t', '-f', 'ssid', 'dev', 'wifi']);
      if (result.exitCode == 0) {
        return result.stdout.toString().split("\n").where((element) => element.isNotEmpty).toList();


      } else {
        print('Error running nmcli command: ${result.stderr}');
      }
    } catch (e) {
      print('Error running nmcli command: $e');
    }
    return [];
  }

  List<String> _extractPasswordProtectedSSIDs(String output) {
    final ssidList = <String>[];
    if (output.isNotEmpty) {
      final networks = output.split('\n');
      for (final network in networks) {
        final parts = network.split(':');
        if (parts.length == 2 && parts[1].trim().toLowerCase() != 'none') {
          ssidList.add(parts[0]);
        }
      }
    }
    return ssidList;
  }

  Future<List<String>> listPasswordProtectedWiFiNetworks() async {
    await enableWifi();
    try {
      final result = await Process.run('nmcli', ['-t', '-f', 'ssid,security', 'dev', 'wifi']);
      if (result.exitCode == 0) {
        return  _extractPasswordProtectedSSIDs(result.stdout.toString());
      } else {
        print('Error running nmcli command: ${result.stderr}');
      }
    } catch (e) {
      print('Error running nmcli command: $e');
    }
    return [];
  }


  bool isLinuxConnectedToWiFi() {
    try {
      final file = File('/proc/net/wireless');
      final content = file.readAsStringSync();
      return content.contains(instance.configValues!.ifaceWifi); // Replace 'wlp' with your WiFi interface name prefix
    } catch (e) {
      print('Error checking WiFi status: $e');
    }
    return false;
  }


  Future<bool> isLinuxAccessPointEnabled() async {

      const command =
      """pkexec create_ap --list-running """;

      try {
        final res = await Shell().run(command);

         return  res.first.outText.isNotEmpty;
      } catch (e) {
        print('Error running create_ap: $e');
        return false;
      }

  }


  Future<void> enableWifi() async {
    const command =
    """nmcli radio wifi on """;

    try {
      final res = await Shell().run(command);

    } catch (e) {
      print('Error running create_ap: $e');
    }

  }



  Future<bool> connectToWifi(String ssid , String? password  ) async {

    bool secure = (password != null);
    if(Platform.isLinux) {

      final command = secure ?  """ 
           pkexec nmcli dev wifi connect \"$ssid\" password \"$password\"
      """ :
      """pkexec nmcli dev wifi connect \"$ssid\" """;

      try {
        final res = await Shell().run(command);

        return res.first.outText.contains('success');
      } catch (e) {
        print('Error running create_ap: $e');
        return false;
      }
    }
    return false;
  }
  
  Future<int?> startHotspot(
  {Function(Process pro)? onProcess}
      ) async {

    if(Platform.isLinux) {
      final command =
          """pkexec create_ap ${configValues?.ifaceWifi} lo ${configValues?.ssid} ${configValues?.pass} --no-virt""";

      try {
        await Shell().run(command,onProcess: onProcess);

        print('Shell script done!');
      } catch (e) {
        print('Error running create_ap: $e');
        return null;
      }
    }
    else if(Platform.isWindows){

      try {
        Process.runSync('netsh', [
          'wlan',
          'set',
          'hostednetwork',
          'mode=allow',
          'ssid=${configValues!.ssid}',
          'key=${configValues!.pass}'
        ], runInShell: true);

        Process.runSync('netsh', [
          'wlan',
          'start',
          'hostednetwork'
        ], runInShell: true);

        print('Hotspot created successfully!');
      } catch (e) {
        print('Failed to create hotspot: $e');
      }
    }
    return null;
  }

  Future<void> stopHotspot() async {

    if(Platform.isLinux) {
      final command = """
    pkexec create_ap --stop ${configValues?.ifaceWifi}
        """;

      print(command);

      try {
        await Shell().run(command);
        print('Hotspot stopped!');
      } catch (e) {
        print('Error stopping hotspot: $e');
      }
    }else if(Platform.isWindows){

      try {
        Process.runSync('netsh', ['wlan', 'stop', 'hostednetwork'], runInShell: true);
        print('Hotspot stopped successfully!');
      } catch (e) {
        print('Failed to stop hotspot: $e');
      }
    }
  }


  static String generateStringWithPrefix() {
    // Use the device name as a prefix
    String prefix = getDeviceName();

    // Generate four random integers between 0 and 9
    final random = Random();
    final randomIntegers = List.generate(4, (_) => random.nextInt(10));

    // Combine the prefix and random integers to create the final string
    final result = '$prefix${randomIntegers.join()}';

    return result;
  }

  static String generateSecurePassword() {
    final random = Random();
    const String validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#';

    final passwordChars = List.generate(8, (_) => validChars[random.nextInt(validChars.length)]);
    final password = passwordChars.join();

    return password;
  }

  static String getDeviceName(){
    try {
      return  Platform.localHostname; // Obtain the hostname
    } catch (e) {
      print('Error getting hostname: $e');
      return "Device";
    }
  }
}