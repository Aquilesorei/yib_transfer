import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../Providers/SelectionProvider.dart';

enum KindofFile { video, audio, image }

class MediaListScreen extends StatefulWidget {
  final List<String> mediaPaths;
  final KindofFile kind;

  const MediaListScreen(
      {super.key, required this.mediaPaths, required this.kind});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  Map<String, List<String>> mediasByFolder = {};

  @override
  void initState() {
    super.initState();
    _organizeVideosByFolder();
  }

  void _organizeVideosByFolder() {
    mediasByFolder.clear();
    for (var path in widget.mediaPaths) {
      var folderName = basename(File(path).parent.path);

      mediasByFolder[folderName] ??= [];
      mediasByFolder[folderName]!.add(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: mediasByFolder.length,
      itemBuilder: (context, index) {
        var folderName = mediasByFolder.keys.elementAt(index);
        var videos = mediasByFolder[folderName]!;
        return FolderItem(folderName: folderName, videos: videos);
      },
    );
  }
}

class FolderItem extends StatelessWidget {
  final String folderName;
  final List<String> videos;

  const FolderItem({Key? key, required this.folderName, required this.videos})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionProvider = Provider.of<SelectionProvider>(context);

     //bool isSelected = selectionProvider.isAllSelected(videos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title:  Text(
              folderName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ) ,
          /*  trailing:  Checkbox(
              value: isSelected,
              onChanged: (selected) {
                print(selected);
                selectionProvider.toggleAllSelection(videos);
              },
            ),*/
          ),
        ),
        Column(
          children: videos
              .map((video) => GestureDetector(
            onTap: () {
              selectionProvider.toggleFileSelection(video);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectionProvider.isFileSelected(video)
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: Container()/* FutureBuilder<Uint8List?>(
                    future: _getVideoThumbnail(video),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Container();
                      } else if (snapshot.hasData &&
                          snapshot.data != null) {
                        return CircleAvatar(
                          backgroundImage:
                          MemoryImage(snapshot.data!),
                        );
                      } else {
                        return Container(); // Empty container if data is null
                      }
                    },
                  )*/,
                ),
                trailing: Checkbox(
                  value:  selectionProvider.isFileSelected(video),
                  onChanged: (selected) {
                    selectionProvider.toggleFileSelection(video);
                  },
                ),
                title: Text(basename(video)),
                onTap: () {
                  // TODO: Handle onTap
                },
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  // ignore: unused_element
  Future<Uint8List?> _getVideoThumbnail(String videoPath) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );
      return uint8list;
    } catch (e) {
      print('Error loading thumbnail: $e');
      return null;
    }
  }
}