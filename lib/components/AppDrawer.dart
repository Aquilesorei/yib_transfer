import 'dart:io';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../Providers/theme_provider.dart';
import '../routes/routes.dart';
import 'ThemeToggleSwitch.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);

    return Drawer(
      backgroundColor: themeManager.isDarkMode ? const Color(0xff1e1e24) : Colors.white,
      child: ListView(
        children: [
          const ListTile(
            title: Text('Dark Theme'),
            trailing: ThemeToggleSwitch(),
          ),
          ListTile(
            onTap: () {
              Routes.toHome();
            },
            leading: const Icon(Icons.home), // Home icon
            title: const Text('Home'),
          ),
          ListTile(
            onTap: () {
              Routes.toTransfer();
            },
            title: const Text('File Explorer'),
            leading: const Icon(Icons.folder), // Folder icon
          ),

          ListTile(
            onTap: () {
              Routes.toProgress();
            },
            title: const Text('Transfer Progress'),
            leading: const Icon(Icons.update), // Update/refresh icon
          ),

          ListTile(
            onTap: () {
              Routes.toHistory();
            },
            title: const Text('Transfer History'),
            leading: const Icon(Icons.history),
          ),

         if(Platform.isLinux) ListTile(
            onTap: () {
            //  Routes.toWifiScanner();
              Routes.toHotSpotCodeQr();
            },
            title: const Text('Wifi scanner'),
            leading: const Icon(Icons.wifi), // Folder icon
          ),
        ],
      ),
    );

  }
}
