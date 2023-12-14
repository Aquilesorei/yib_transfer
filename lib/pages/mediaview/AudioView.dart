
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../Providers/SelectionProvider.dart';



class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  _SongsState createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  // Main method.
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Indicate if application has permission to the library.
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();

    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);

    // Check and request for permission.
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );

    // Only call update the UI if application has all required permissions.
    _hasPermission ? setState(() {}) : null;
  }

  @override
  Widget build(BuildContext context) {

    final selectionProvider = Provider.of<SelectionProvider>(context);
    return Container(
      child: !_hasPermission
          ? noAccessToLibraryWidget()
          : FutureBuilder<List<SongModel>>(
        // Default values:
        future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, item) {
          // Display error, if any.
          if (item.hasError) {
            return Text(item.error.toString());
          }

          // Waiting content.
          if (item.data == null) {
            return const CircularProgressIndicator();
          }

          // 'Library' is empty.
          if (item.data!.isEmpty) return const Text("Nothing found!");

          // You can use [item.data!] direct or you can create a:
          // List<SongModel> songs = item.data!;
          return ListView.builder(
            itemCount: item.data!.length,
            itemBuilder: (context, index) {
              final SongModel song = item.data![index];
              final isSelected = selectionProvider.isFileSelected(song.uri ?? song.title);

                final uri = song.uri;

                print(uri);

              return ListTile(
                title: Text(item.data![index].title),
                subtitle: Text(item.data![index].artist ?? "No Artist"),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (selected) {
                    selectionProvider.toggleFileSelection(song.uri ?? song.title);
                  },
                ),

                leading: QueryArtworkWidget(
                  controller: _audioQuery,
                  id: item.data![index].id,
                  type: ArtworkType.AUDIO,
                ),
              );
            },
          );
        },
      ),
    );
  }


/*
  Widget test(){
    return Container(
      child: !_hasPermission
          ? noAccessToLibraryWidget()
          : FutureBuilder<List<SongModel>>(
        // ...

        itemBuilder: (context, index) {
          final song = item.data![index];
          final isSelected = selectionProvider.isImageSelected(song.id);

          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist ?? "No Artist"),
            trailing: const Icon(Icons.arrow_forward_rounded),
            leading: GestureDetector(
              onTap: () {
                selectionProvider.toggleImageSelection(song.id);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: QueryArtworkWidget(
                      controller: _audioQuery,
                      id: song.id,
                      type: ArtworkType.AUDIO,
                    ),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child:
                ),
              ),
            ),
          );
        },
      ),
    );
  }*/

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
