

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ztransfer/components/Gallery.dart';

import '../../Providers/ImageProvider.dart' as ip;

class ImageView extends StatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  void initState() {
    super.initState();
    final mediaProvider = Provider.of<ip.ImageProvider>(context, listen: false);
    mediaProvider.startFetching();
  }

  @override
  Widget build(BuildContext context) {
    return  Consumer<ip.ImageProvider>(
        builder: (context, mediaProvider, child) {
          if (mediaProvider.fetching) {
            return Center(
              child: Text(
                'Fetching: ${mediaProvider.current}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          } else {
            return  Gallery(localImages: mediaProvider.images);
          }
        },
      );
  }
}
