

import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class FetchAllImages {

  List<String> imagesDirectories = [];
  List<String> allDirectories = [];
  List<String> myDirectories = [];
  int myIndex = 0;

  Future<List<String>> getAllImages({Function(String)? onImageFetched}) async {
    print("fetching");

    List<Directory>? extDir = await getExternalStorageDirectories();
    List<String> pathForCheck = [];

    for (var path in extDir!) {
      String actualPath = path.path;
      int found = 0;
      int startIndex = 0;
      for (int pathIndex = actualPath.length - 1; pathIndex >= 0; pathIndex--) {
        if (actualPath[pathIndex] == "/") {
          found++;
          if (found == 4) {
            startIndex = pathIndex;
            break;
          }
        }
      }
      var splitPath = actualPath.substring(0, startIndex + 1);
      pathForCheck.add(splitPath);
    }

    for (var pForCheck in pathForCheck) {
      Directory directory = Directory(pForCheck);
      if (directory.statSync().type == FileSystemEntityType.directory) {
        var initialDirectories = directory.listSync().map((e) {
          return e.path;
        }).toList();

        for (var directories in initialDirectories) {
          if (directories.toString().endsWith('.jpg') ||
              directories.toString().endsWith('.jpeg') ||
              directories.toString().endsWith('.png')) {
            print("FETCHING : $directories");
            imagesDirectories.add("$directories");
          }
          if (!directories.toString().contains('.')) {
            String dirs = "$directories/";
            myDirectories.add(dirs);
          }
        }
      }
    }

    for (; myIndex < myDirectories.length; myIndex++) {
      var myDirs = Directory(myDirectories[myIndex]);
      if (myDirs.statSync().type == FileSystemEntityType.directory) {
        var initialDirectories = myDirs.listSync().map((e) {
          return e.path;
        }).toList();
        for (var image in initialDirectories) {
          final mimeType = lookupMimeType(image);

          if (mimeType != null && mimeType.startsWith('image/')) {
            print("FETCHING : $image");

            if (onImageFetched != null) {
              onImageFetched(image);
            }

            imagesDirectories.add(image);
          }
        }
        for (var directories in initialDirectories) {
          if (!directories.toString().contains('.')) {
            String dirs = "$directories/";
            var tempDir = Directory(dirs);
            if (tempDir.statSync().type == FileSystemEntityType.directory) {
              var imageDirs = tempDir.listSync().map((e) {
                return e.path;
              }).toList();
              for (var image in imageDirs) {
                if (image.toString().endsWith('.jpg') ||
                    image.toString().endsWith('.jpeg') ||
                    image.toString().endsWith('.png')) {
                  print("FETCHING : $image");

                  if (onImageFetched != null) {
                    onImageFetched(image);
                  }

                  imagesDirectories.add(image);
                }
              }
            }
          }
        }
      }
    }

    return imagesDirectories;
  }
}
