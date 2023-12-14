

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/SelectionProvider.dart';

class YibImageView extends StatelessWidget {
  final String imagePath;
  final double size;

  const YibImageView({Key? key, required this.imagePath, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionProvider = Provider.of<SelectionProvider>(context);
    final isSelected = selectionProvider.isFileSelected(imagePath);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
        ),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Checkbox(
          value: isSelected,
          onChanged: (selected) {
            selectionProvider.toggleFileSelection(imagePath);
          },
        ),
      ),
    );
  }
}