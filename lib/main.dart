import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:yib_transfer/Managers/HotspotManager.dart';
import 'package:yib_transfer/ObjectPool.dart';
import 'package:yib_transfer/Providers/SelectionProvider.dart';
import 'package:yib_transfer/models/FileTransferInfo.dart';

import 'package:yib_transfer/routes/routes.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Providers/FileTransferProvider.dart';
import 'Providers/VideoProvider.dart';
import 'Providers/theme_provider.dart';
import '../../Providers/ImageProvider.dart' as ip;

Future<void> main() async {

//  ObjectPool.instance.initialize(() => FileTransferInfo("", 0, 0.0,0));

  await HotspotManager.initConfig();
  runApp(
      MultiProvider(

        providers: [
          ChangeNotifierProvider<SelectionProvider>(
            create: (_) =>SelectionProvider() ,
          ),
          ChangeNotifierProvider<ip.ImageProvider>(
            create: (_) => ip.ImageProvider(),
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<VideosProvider>(
            create: (context) => VideosProvider(),
          ),
          ChangeNotifierProvider(create: (_) => FileTransferProvider()),
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {




  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    themeProvider.initialize();
    return MaterialApp.router(
        routeInformationParser: const QRouteInformationParser(),
        routerDelegate: QRouterDelegate(Routes.routes),
        debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      );
  }
}
