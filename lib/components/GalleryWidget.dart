import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryWidget extends StatefulWidget {
  final List<String> urlImages;
  final int index;
  final PageController pageController;

  GalleryWidget({super.key,
    required this.urlImages,
    this.index = 0,
  }) : pageController = PageController(initialPage: index);

  @override
  State<GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<GalleryWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gallery',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              // Swipe right
              if (widget.pageController.hasClients) {
                widget.pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (details.primaryVelocity! < 0) {
              // Swipe left
              if (widget.pageController.hasClients) {
                widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        },
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PhotoViewGallery.builder(
                    pageController: widget.pageController,
                    itemCount: widget.urlImages.length,
                    builder: (context, index) {
                      final urlImage = widget.urlImages[index];
                      return PhotoViewGalleryPageOptions(
                        imageProvider: AssetImage(urlImage),
                      );
                    },
                  ),
                  Positioned(
                    left: 16,
                    top: MediaQuery.of(context).size.height / 2,
                    child: IconButton(
                      onPressed: () {
                        if (widget.pageController.hasClients) {
                          widget.pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const Icon(Icons.navigate_before, size: 40),
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).size.height / 2,
                    child: IconButton(
                      onPressed: () {
                        if (widget.pageController.hasClients) {
                          widget.pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const Icon(Icons.navigate_next, size: 40),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
