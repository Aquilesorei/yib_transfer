
import 'package:flutter/material.dart';

import '../Fetch/FetchAllImages.dart';


class ImageProvider extends ChangeNotifier {
  List<String> images = [];
  bool fetching = false;
  String current = '';

  Future<void> startFetching() async {
    fetching = true;
    notifyListeners();

    FetchAllImages ob = FetchAllImages();
    await ob.getAllImages(onImageFetched: (String image) {
      current = image;
      notifyListeners();
    }).then((List<dynamic> imgs) {
      images = imgs.map((e) => e as String).toList();
      fetching = false;
      notifyListeners();
    });
  }
}
