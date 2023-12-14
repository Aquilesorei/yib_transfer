import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yib_transfer/Providers/SelectionProvider.dart';
import 'package:yib_transfer/pages/InstalledAppPage.dart';

import '../Providers/FileTransferProvider.dart';
import '../components/AppDrawer.dart';
import '../routes/FileTransfert.dart';
import 'FileExplorer.dart';
import 'mediaview/AudioView.dart';
import 'mediaview/ImageView.dart';
import 'mediaview/VideoView.dart';
import 'package:yifi/yifi.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {


  @override
  Widget build(BuildContext context) {
    Widget platformWidget;
    final selectionProvider = Provider.of<SelectionProvider>(context);

    if (Platform.isWindows || Platform.isLinux) {
      return Scaffold(
        drawer: const AppDrawer(),
        endDrawerEnableOpenDragGesture: true,
        appBar:AppBar(
          centerTitle: true,
          title:  (selectionProvider.selectedFiles.isEmpty) ? const Text("Yib's Transfer") : Text(displaySelect(selectionProvider.selectedFiles.length),
          ),actions: [
         if (selectionProvider.selectedFiles.isNotEmpty) Tooltip(
           message: 'Clear all selections',
           child: IconButton(onPressed: (){
              selectionProvider.clearSelection();
            }, icon: const Icon(Icons.clear_all)),
         ),

        ],
        ),
        body: const FileExplorer(),
      );
    }  else if (Platform.isAndroid) {
      return _AndroidView();
    } else if (Platform.isIOS) {
      platformWidget = const Text("Running on iOS");
    } else if (Platform.isMacOS) {
      return Scaffold(
        drawer: const AppDrawer(),
        endDrawerEnableOpenDragGesture: true,
        appBar: AppBar(
          title: const Text('Yib\'s Transfer'),
          centerTitle: true,
        ),
        body: const FileExplorer(),
      );
    } else {
      platformWidget = const Text("Running on an unknown platform");
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfer'),
      ),
      body: platformWidget,
    );
  }
}
String displaySelect(int len) {
  return len == 0
      ? 'no file selected'
      : len == 1
      ? '$len file selected'
      : '$len files selected';
}

class _AndroidView extends StatefulWidget {
  @override
  _AndroidViewState createState() => _AndroidViewState();
}

class _AndroidViewState extends State<_AndroidView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _storagePermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    final int androidVersion = await Yifi.getPlatformVersion() ?? 0;

    Permission permission = Permission.storage;

    if(androidVersion >= 13){
      permission = Permission.manageExternalStorage;
    }
    var status = await permission.status;
    if (!status.isGranted) {
      var result = await permission.request();
      setState(() {
        _storagePermissionGranted = result.isGranted;
      });
    } else {
      setState(() {
        _storagePermissionGranted = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final selectionProvider = Provider.of<SelectionProvider>(context);

    final provider = Provider.of<FileTransferProvider>(context);

    return Scaffold(
      drawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Yib's Transfer"),
            Text(displaySelect(selectionProvider.selectedFiles.length))
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history)),
            Tab(icon: Icon(Icons.apps)),
            Tab(icon: Icon(Icons.image)),
            Tab(icon: Icon(Icons.audiotrack)),
            Tab(icon: Icon(Icons.video_library)),
            Tab(icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text('History')),
          // Apps Tab Content
          _storagePermissionGranted
              ? const Center(child: InstalledAppsPage())
              : getPermission(),
          // Images Tab Content
          _storagePermissionGranted
              ? const Center(child: ImageView())
              : getPermission(),
          // Audio Tab Content
          _storagePermissionGranted
              ? const Center(child: Songs())
              : getPermission(),
          // Video Tab Content
          _storagePermissionGranted
              ? const Center(child: VideoView())
              : getPermission(),
          // File Explorer Tab Content
          _storagePermissionGranted
              ? const Center(child: FileExplorer())
              : getPermission(),
        ],
      ),
      floatingActionButton: selectionProvider.selectedFiles.isEmpty ? Container() : FloatingActionButton(
        onPressed: () {
          final files = selectionProvider.selectedFiles.map((path) => File(path)).toList();
          selectionProvider.clearSelection();

          if(files.isNotEmpty) {
            FileTransfer.instance.sendFiles(
              files,
             provider,
            );
          }
        },
        child: const Icon(Icons.send),
      ),
    );
  }

  Widget getPermission() {
    return Center(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              """
         You have to allow access to storage before""",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
              onPressed: _requestStoragePermission,
              child: const Text('Grant access'))
        ],
      ),
    );
  }
}
