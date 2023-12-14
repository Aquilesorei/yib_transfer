
import 'package:flutter/material.dart';

import '../Fetch/FetchAllVideos.dart';

class VideosProvider extends ChangeNotifier {
  List<String> videos = [];
  bool fetching = false;
  String current = '';

  Future<void> startFetching() async {
    fetching = true;
    notifyListeners();

    FetchAllVideos ob = FetchAllVideos();
    await ob.getAllVideos(onVideoFetched: (String video) {
      current = video;
      notifyListeners();
    }).then((List<dynamic> vids) {
      videos = vids.map((e) => e as String).toList();
      fetching = false;
      notifyListeners();
    });
  }
}
