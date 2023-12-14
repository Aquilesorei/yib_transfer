import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/VideoProvider.dart';
import 'commons/MediaListScreen.dart';

class VideoView extends StatefulWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  @override
  void initState() {
    super.initState();
    final mediaProvider = Provider.of<VideosProvider>(context, listen: false);
    mediaProvider.startFetching();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VideosProvider>(
        builder: (context, mediaProvider, child) {
          if (mediaProvider.fetching) {
            return Center(
              child: Text(
                'Fetching: ${mediaProvider.current}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          } else {
            return  MediaListScreen(mediaPaths: mediaProvider.videos,kind: KindofFile.video,);
          }
        },
      ),
    );
  }
}
