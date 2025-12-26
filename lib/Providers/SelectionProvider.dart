import 'package:flutter/material.dart';

class SelectionProvider extends ChangeNotifier {
  Set<String> selectedFiles = {};

  bool isFileSelected(String filePath) {
    return selectedFiles.contains(filePath);
  }


  void toggleFileSelection(String filePath) {
    if (selectedFiles.contains(filePath)) {
      selectedFiles.remove(filePath);
    } else {
      selectedFiles.add(filePath);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedFiles.clear();
    notifyListeners();
  }


  void toggleAllSelection(List<String> filePaths) {
    if (isAllSelected(filePaths)) {
      selectAllFiles(filePaths);
    } else {
      deselectAllFiles(filePaths);
    }
  }

  bool isAllSelected(List<String> filePaths){
    return selectedFiles.containsAll(filePaths);
  }
  void selectAllFiles(List<String> filePaths) {
    selectedFiles.addAll(filePaths);
    notifyListeners();
  }

  void deselectAllFiles(List<String> filePaths) {
    selectedFiles.removeAll(filePaths);
    notifyListeners();
  }
}
