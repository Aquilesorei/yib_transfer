import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yib_transfer/models/PeerEndpoint.dart';

import '../Providers/FileTransferProvider.dart';
import '../Providers/SelectionProvider.dart';
import '../components/AppDrawer.dart';
import '../routes/FileTransfert.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<StatefulWidget> {
  final FileManagerController controller = FileManagerController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: controller,
      child: Scaffold(
        drawer: const AppDrawer(),
        endDrawerEnableOpenDragGesture: true,
        appBar: appBar(context),
        floatingActionButton:
            Consumer2<FileTransferProvider, SelectionProvider>(
          builder: (context, fileTransferProvider, selectionProvider, child) {
            return  selectionProvider.selectedFiles.isEmpty ? Container() : FloatingActionButton(
              onPressed: () {
                final files = selectionProvider.selectedFiles
                    .map((path) => File(path))
                    .toList();
                selectionProvider.clearSelection();

                if (files.isNotEmpty) {
                  FileTransfer.instance.sendFiles(
                    files,
                    fileTransferProvider,
                  );
                }
              },
              child: const Icon(Icons.send),
            );
          },
        ),
        body: FileManager(
          controller: controller,
          builder: (context, snapshot) {
            final List<FileSystemEntity> entities = snapshot;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = entities[index];
                return CustomListTile(entity: entity, controller: controller);
              },
            );
          },
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
        /*       Consumer<SelectionProvider>(
          builder: (context, selectionProvider, child) {
            if(selectionProvider.selectedFiles.isEmpty){
              return Container();
            }else{
              return const Tooltip(
                message: "Select all",

              )
            }
          },
        ),*/
        IconButton(
          onPressed: () => sort(context),
          icon: const Icon(Icons.sort_rounded),
        ),
        IconButton(
          onPressed: () => selectStorage(context),
          icon: const Icon(Icons.sd_storage_rounded),
        )
      ],
      title: ValueListenableBuilder<String>(
        valueListenable: controller.titleNotifier,
        builder: (context, title, _) => Text(title),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await controller.goToParentDirectory();
        },
      ),
    );
  }

  Future<void> selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList
                        .map((e) => ListTile(
                              title: Text(
                                FileManager.basename(e),
                              ),
                              onTap: () {
                                controller.openDirectory(e);
                                Navigator.pop(context);
                              },
                            ))
                        .toList()),
              );
            }
            return const Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: const Text("Name"),
                  onTap: () {
                    controller.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("Size"),
                  onTap: () {
                    controller.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("Date"),
                  onTap: () {
                    controller.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("type"),
                  onTap: () {
                    controller.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  createFolder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController folderName = TextEditingController();
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    controller: folderName,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Create Folder
                      await FileManager.createFolder(
                          controller.getCurrentPath, folderName.text);
                      // Open Created Folder
                      controller.setCurrentPath =
                          "${controller.getCurrentPath}/${folderName.text}";
                    } catch (e) {}

                    Navigator.pop(context);
                  },
                  child: const Text('Create Folder'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget subtitle(FileSystemEntity entity) {
  return FutureBuilder<FileStat>(
    future: entity.stat(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        if (entity is File) {
          int size = snapshot.data!.size;

          return Text(
            FileManager.formatBytes(size),
          );
        }
        return Text(
          "${snapshot.data!.modified}".substring(0, 10),
        );
      } else {
        return const Text("");
      }
    },
  );
}

class CustomListTile extends StatelessWidget {
  final FileSystemEntity entity;
  final FileManagerController controller;
  const CustomListTile(
      {super.key, required this.entity, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionProvider>(
      builder: (context, selectionProvider, child) {
        return Card(
          child: ListTile(
            leading: selectionProvider.isFileSelected(entity.path)
                ? const Icon(Icons.done, color: Colors.green, size: 64)
                : FileManager.isFile(entity)
                    ? const Icon(Icons.feed_outlined)
                    : const Icon(Icons.folder),
            title: Text(FileManager.basename(
              entity,
              showFileExtension: true,
            )),
            subtitle: subtitle(entity),
            onLongPress: () {
              selectionProvider.toggleFileSelection(entity.path);
            },
            onTap: () async {
              if (FileManager.isDirectory(entity)) {
                // open the folder

                if (selectionProvider.selectedFiles.isEmpty) {
                  controller.openDirectory(entity);
                } else {
                  selectionProvider.toggleFileSelection(entity.path);
                }

                // delete a folder
                // await entity.delete(recursive: true);

                // rename a folder
                // await entity.rename("newPath");

                // Check weather folder exists
                // entity.exists();

                // get date of file
                // DateTime date = (await entity.stat()).modified;
              } else {
                // FileTransfer.instance.sendFileToServer(File(entity.path), PeerEndpoint("127.0.0.1", FileTransfer.instance.port), provider);

                selectionProvider.toggleFileSelection(entity.path);

                //Routes.toProgress();
                // delete a file
                // await entity.delete();

                // rename a file
                // await entity.rename("newPath");

                // Check weather file exists
                // entity.exists();

                // get date of file
                // DateTime date = (await entity.stat()).modified;

                // get the size of the file
                // int size = (await entity.stat()).size;
              }
            },
          ),
        );
      },
    );
  }
}
