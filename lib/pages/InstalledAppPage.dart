import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppsPage extends StatelessWidget {
  const InstalledAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppInfo>>(
        future: InstalledApps.getInstalledApps(true, true),
        builder:
            (BuildContext buildContext, AsyncSnapshot<List<AppInfo>> snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? snapshot.hasData
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        AppInfo app = snapshot.data![index];
                        return GestureDetector(
                          child: AppInfoWidget(appName: app.name!,appIcon: app.icon!,versionInfo: app.getVersionInfo(),),
                          onTap: () => InstalledApps.startApp(app.packageName!),
                          onLongPress: () =>
                          InstalledApps.openSettings(app.packageName!),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                          "Error occurred while getting installed apps ...."))
              : const Center(child: Text("Getting installed apps ...."));
        },
      );
  }
}


class AppInfoWidget extends StatefulWidget {
  final String appName;
  final Uint8List appIcon;
  final String versionInfo;

  const AppInfoWidget({
    Key? key,
    required this.appName,
    required this.appIcon,
    required this.versionInfo,
  }) : super(key: key);

  @override
  State<AppInfoWidget>  createState() => _AppInfoWidgetState();
}

class _AppInfoWidgetState extends State<AppInfoWidget> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Image.memory(widget.appIcon),
            ),
            Text(
              widget.appName,
              overflow: TextOverflow.ellipsis,
            ),
            // Text(widget.versionInfo), 
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Checkbox(
            checkColor: Colors.white,
            value: isChecked,
            onChanged: (bool? value) {
              setState(() {
                isChecked = value!;
              });
            },
          ),
        )
      ],
    );
  }
}