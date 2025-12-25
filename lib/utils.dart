import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yifi/yifi.dart';


const String _DownloadDirName = "Yibloa";
final sep = Platform.isWindows ? "\\" : "/";



Future<int> getAndroidSDkVersion() async {
  var androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.version.sdkInt;
}




const List<String> FILE_SIZE_UNITS = [
  "B",
  "KB",
  "MB",
  "GB",
  "TB",
  "PB",
  "EB",
  "ZB",
  "YB"
];
int FILE_SIZE_UNITS_LAST_INDEX = FILE_SIZE_UNITS.length - 1;

String getFormattedFileSize(int size, {bool withUnit = true}) {
  if (size <= 0) {
    return "0${withUnit ? " ${FILE_SIZE_UNITS[0]}" : ""}";
  } else {
    final unitIndex = log(size.toDouble()) ~/ log(1024.0).clamp(0, FILE_SIZE_UNITS_LAST_INDEX);
    final dsize = size.toDouble() / pow(1024.0, unitIndex);
    final formattedSize = dsize.toStringAsFixed(2);
    final res = withUnit
        ? "$formattedSize ${FILE_SIZE_UNITS[unitIndex]}"
        : formattedSize;
    return res;
  }
}

Future<bool> isPortAvailable(int port) async {
  try {
    final socket = await Socket.connect('localhost', port,
        timeout: const Duration(milliseconds: 1000));
    socket.close();
    return false; // Port is not available since connection was successful
  } catch (e) {
    return true; // Port is available
  }
}

Future<int> findAvailablePort() async {
  final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4, includeLinkLocal: true);

  for(var inter in interfaces){
    print(inter.name);

    if(Platform.isLinux || Platform.isWindows){
      //wlan0 and wlo1

    }else if(Platform.isAndroid){
      //ap0
    }
    for (InternetAddress address in inter.addresses) {
      print(address);
    }
  }


  try {
// Try VPN connection first
    NetworkInterface vpnInterface =
        interfaces.firstWhere((element) => element.name == "tun0");
    return vpnInterface.addresses.first.address;
  } on StateError {
// Try wlan connection next
    try {
      NetworkInterface interface =
          interfaces.firstWhere((element) => element.name == "wlan0");

      return interface.addresses.first.address;

    } catch (ex) {
// Try any other connection next
      try {
        NetworkInterface interface = interfaces.firstWhere(
            (element) => !(element.name == "tun0" || element.name == "wlan0" || element.name == "wlo1" || element.name == "ap0"  || element.name.startsWith('wlan')));

      //  interface.addresses.forEach((element) {print(element);});
        return interface.addresses.first.address;
      } catch (ex) {
        return null;
      }
    }
  }
}

Future<String?> getLocalIpAddress2() async {

  try {
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: true);

    final preferredInterfaces = interfaces.where((interface) =>
    interface.name.contains("tun0") ||
        interface.name.startsWith("ap")  ||
        interface.name.startsWith('wl'));

    final validInterface = preferredInterfaces.isNotEmpty
        ? preferredInterfaces.first
        : interfaces.firstWhere(
          (interface) => interface.name.startsWith('wl'),
      orElse: () => interfaces.first,
    );

    return validInterface.addresses.first.address;
  } catch (e) {
    return null;
  }
}

const _subDirNames = ['Audio', 'Video', 'App', 'Image', 'Folders','Documents','Others'];

String getFilePath(String fileName, String mimeType, String basePath) {

  final mimeTypeToSubDirectory = {
    if (mimeType.startsWith('audio/')) ...{
      'audio': _subDirNames[0],
    },
    if (mimeType.startsWith('video/')) ...{
      'video': _subDirNames[1],
    },
    if (mimeType == 'application/vnd.android.package-archive') ...{
      'application': _subDirNames[2],
    },
    if (mimeType.startsWith('image/')) ...{
      'image': _subDirNames[3],
    },
    if(mimeType.contains("document") || mimeType.contains('pdf'))...{
      'document' : _subDirNames[5]
    }
  };

  final subDirectory = mimeTypeToSubDirectory.entries
      .firstWhere((entry) => entry.key == mimeType.split('/').firstOrNull,
      orElse: ()  {
        if(mimeType.contains("document") || mimeType.contains('pdf')){
          return MapEntry('document', _subDirNames[5]);
        }
        return MapEntry('', _subDirNames.last);
      })
      .value;

  return "$basePath$sep$subDirectory$sep$fileName";
}



Future<String> handleFileDuplication(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    // File doesn't exist, no need for renaming.
    return file.path;
  }

  final name  =  basename(filePath);
  final ext = extension(filePath);

  int count = 1;
  String newFileName;

  do {
    newFileName = '$name($count)$ext';
    count++;
  } while (await File('${file.parent.path}$sep$newFileName').exists());

  return '${file.parent.path}$sep$newFileName';
}


Future<String> getDownloadFolder(String filename,String mimeType) async {

    if(Platform.isAndroid){
      return  await _getAndroidDownloadFolder(filename,mimeType);
    } else if(Platform.isWindows){
      return await _getWindowsDownloadFolder(filename,mimeType);
    }else{
      return  await _getLinuxDownloadFolder(filename,mimeType);
    }
}

Future<String> _getAndroidDownloadFolder(String filename,String mimeType) async {
  const folderName = _DownloadDirName;
  final path = Directory("storage/emulated/0/$folderName");


  int vers =   await getAndroidSDkVersion();
  final Permission permission =  (vers <33) ? Permission.storage : Permission.manageExternalStorage;
  var status = await permission.status;
  if (!status.isGranted) {

    await permission.request();
  }
  if ((await path.exists())) {
    return  getFilePath(filename,mimeType, path.path);
  } else {
    path.create();

    for (final subDirName in _subDirNames) {
      final subDir = Directory('${path.path}/$subDirName');
      await subDir.create(recursive: true);
    }
    return  getFilePath(filename,mimeType, path.path);
  }
}




Future<String> _getLinuxDownloadFolder(String filename,String mimeType) async {
  const folderName = _DownloadDirName;
  final home = getHome();

  final basePath = home != null ? Directory('$home/$folderName') : Directory(folderName);


  if ((await basePath.exists())) {
    return  getFilePath(filename,mimeType, basePath.path);
  } else {
    await basePath.create(recursive: true);

    for (final subDirName in _subDirNames) {
      final subDir = Directory('${basePath.path}/$subDirName');
      await subDir.create(recursive: true);
    }

    return  getFilePath(filename,mimeType, basePath.path);

  }


}

Future<String> _getWindowsDownloadFolder(String filename,String mimeType) async {
  final home = getHome();

  final basePath = home != null ? Directory('$home\\$_DownloadDirName') : Directory(_DownloadDirName);

  if ((await basePath.exists())) {
    return  getFilePath(filename,mimeType, basePath.path);
  } else {
    await basePath.create(recursive: true);

    for (final subDirName in _subDirNames) {
      final subDir = Directory('${basePath.path}\\$subDirName');
      await subDir.create(recursive: true);
    }

    return  getFilePath(filename,mimeType, basePath.path);
  }

}



String? getHome(){
  String? home ;
  Map<String, String> envVars = Platform.environment;
  if  (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  return home;
}

