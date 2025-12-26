

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../components/AppDrawer.dart';
import '../routes/file_transfer.dart';


class DisplayQR extends StatefulWidget {
  const DisplayQR({super.key});

  @override
  State<DisplayQR> createState() => _DisplayQRState();
}

class _DisplayQRState extends State<DisplayQR> {


   String ip ='';
   int port =0;
  @override
  void initState(){
    super.initState();

   setIPandPort();

  }

  Future<void> setIPandPort() async {

     setState(() {
       ip = FileTransfer.instance.initialEndpoint;
       port = FileTransfer.instance.port;
     });
   }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:  const AppDrawer(),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(title: const Text("Receive"),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Please scan to Receive file",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: QrImageView(
                data: "$ip:$port",
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
         SelectionArea(
           child: Center(
             child: RichText(
               textAlign: TextAlign.center,
                text:  TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: 16.0,
                  ),
                  children: [
                    const TextSpan(text: 'Or alternatively your can enter  ', style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(text: '$ip:$port ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'in the peer device ', style: TextStyle(fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
           ),
         ),
        ],
      ),
    );
  }
}

