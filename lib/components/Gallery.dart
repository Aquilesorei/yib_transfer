
import 'package:flutter/material.dart';

import '../routes/routes.dart';
import 'YibImageView.dart';
import 'GalleryWidget.dart';



const whitecolor = Colors.white;
const blackcolor = Colors.black;
class Gallery extends StatefulWidget {

  final List<String> localImages;
  const Gallery({Key? key, required this.localImages}) : super(key: key);
  @override
  State<Gallery> createState() => _GalleryState();
}
class _GalleryState extends State<Gallery> {


  List<String> localImages = [];
  @override
  void initState() {
    super.initState();
    setState(() {
      localImages = widget.localImages;

    });
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.3;
    return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),

                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemBuilder: (context, index) {
                        return RawMaterialButton(
                          child:YibImageView(size: size, imagePath: localImages[index],),
                          onPressed: () => Routes.toGalleryWidget(localImages),
                        );
                      },
                      itemCount: localImages.length,
                    )))
          ],
        ));
  }
}