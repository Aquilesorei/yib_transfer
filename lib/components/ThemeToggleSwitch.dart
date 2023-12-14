import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/theme_provider.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key,});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);

    return Switch(
      value: themeManager.isDarkMode,
      onChanged: (bool value) {
        themeManager.toggleTheme();
      },
      activeColor: Colors.amber,
      activeTrackColor: Colors.amber,
      inactiveThumbColor: Colors.black,
      inactiveTrackColor: Colors.grey.shade400,
    );
  }
}