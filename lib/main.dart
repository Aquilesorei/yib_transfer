import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:yib_transfer/Managers/HotspotManager.dart';
import 'package:yib_transfer/Providers/SelectionProvider.dart';

import 'package:yib_transfer/routes/routes.dart';

import 'Providers/FileTransferProvider.dart';
import 'Providers/VideoProvider.dart';
import 'Providers/theme_provider.dart';
import 'Providers/ImageProvider.dart' as ip;
import 'routes/file_transfer.dart';
import 'services/history_service.dart';

final GlobalKey<ScaffoldMessengerState> scannerMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await HotspotManager.initConfig();
  await HistoryService.instance.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SelectionProvider>(
          create: (_) => SelectionProvider(),
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
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize theme provider once
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.initialize();
    
    // Listen for file transfer errors
    FileTransfer.instance.onError.listen((error) {
      scannerMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(error.userFriendlyMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              scannerMessengerKey.currentState?.hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
    
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      scaffoldMessengerKey: scannerMessengerKey,
      routeInformationParser: const QRouteInformationParser(),
      routerDelegate: QRouterDelegate(Routes.routes),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
