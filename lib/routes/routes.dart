
import 'package:qlevar_router/qlevar_router.dart';

import '../pages/HomePage.dart';
import '../pages/FileExplorer.dart'    deferred as exp;

import '../pages/network_analysis_widget.dart';
import '../pages/PeerConnectionSetupPage.dart';
import '../pages/TransferPage.dart'    deferred as tf;
import '../pages/Scanner.dart'    deferred as sc;
import '../pages/DisplayQR.dart'    deferred as disp;
import '../pages/InstalledAppPage.dart'  deferred as insta;
import '../components/GalleryWidget.dart' deferred as gal;
import '../pages/ProgressScreen.dart' deferred as gress;
import '../pages/EnterEndPointWidget.dart' deferred as enter;
import '../pages/WifiScanner.dart'  deferred as wsc;
import '../pages/HotspotQRCode.dart' deferred as hts;
import '../pages/historyPage.dart' deferred as hist;
import 'deferred_loader.dart';


class Routes {

  static const String home = "Home";
  static const String explorer = "explorer";
  static const String scan = "scanner";
  static const String transfer = "transfer";
  static const String display = "displayqr";
  static const String installed  = "installed";
  static const String galleryWidget = "gallerywiget";
  static const String progressScreen = "progress";
  static  const String enterEndpoint = "enterendpoint";
  static const String  setuPage = "setup";
  static const String wscan = "wifiscanner";
  static const String hsp = "hostpotcodeqr";
  static const analyis =  "analysis";
  static const String history = "history";

  static void toHome() => QR.to('/home');
  static void toExplorer() => QR.toName(explorer);
  static void toScanner() => QR.toName(scan);
  static void toTransfer() => QR.toName(transfer);
  static void toDisplayQR() => QR.toName(display);
  static void toInstalled() => QR.toName(installed);
  static void toProgress() => QR.toName(progressScreen);
  static void toEnterEndPoint() => QR.toName(enterEndpoint);
  static void toWifiScanner() => QR.toName(wscan);
  static void toHotSpotCodeQr() => QR.toName(hsp);
  static void toHistory() => QR.toName(history);
  static void toSetupPage(String des) => QR.toName(setuPage,params: {
    "dest" : des
  });
  static void toGalleryWidget( List<String> imgs) => QR.toName(galleryWidget,params: {
    'imgs' : imgs,
  });

  static final routes = <QRoute>[

    QRoute(
        name :home ,
        path: '/',
        builder: () => const HomePage()
    ),


    QRoute(
        path: '/home',
        builder: () =>const HomePage()
    ),
    QRoute(
        path: '/$analyis',
        name: analyis,
        builder: () =>const NetworkAnalysisWidget(),
    ),
    QRoute(
      name: explorer,
      path: '/explorer',
      builder: () => exp.FileExplorer(),
      middleware: [
        DefferedLoader(exp.loadLibrary),
      ],
    ),

    QRoute(
      name: hsp,
      path: '/$hsp',
      builder: () => hts.HotspotQRCode(),
      middleware: [
        DefferedLoader(hts.loadLibrary),
      ],
    ),

    QRoute(
      name: wscan,
      path: '/$wscan',
      builder: () => wsc.WifiScanner(),
      middleware: [
        DefferedLoader(wsc.loadLibrary),
      ],
    ),
    QRoute(
      name: setuPage,
      path: '/$setuPage/:dest',
      builder: () => PeerConnectionSetupPage(nextDest: QR.params['dest'].toString(),),
    /*  middleware: [
        DefferedLoader(setup.loadLibrary),
      ],*/
    ),
    QRoute(
      name: enterEndpoint,
      path: '/$enterEndpoint',
      builder: () => enter.EnterEndPointWidget(),
      middleware: [
        DefferedLoader(enter.loadLibrary),
      ],
    ),
    QRoute(
      name: progressScreen,
      path: '/$progressScreen',
      builder: () => gress.ProgressScreen(),
      middleware: [
        DefferedLoader(gress.loadLibrary),
      ],
    ),
    QRoute(
      name: galleryWidget,
      path: '/$galleryWidget',
      builder: () => gal.GalleryWidget(urlImages: QR.params['imgs']?.value as List<String>,),
      middleware: [
        DefferedLoader(gal.loadLibrary),
      ],
    ),
    QRoute(
      name: installed,
      path: '/$installed',
      builder: () => insta.InstalledAppsPage(),
      middleware: [
        DefferedLoader(insta.loadLibrary),
      ],
    ),

    QRoute(
      name: display,
      path: '/displayqr',
      builder: () => disp.DisplayQR(),
      middleware: [
        DefferedLoader(disp.loadLibrary),
      ],
    ),
    QRoute(
      name: transfer,
      path: '/transfert',
      builder: () => tf.TransferPage(),
      middleware: [
        DefferedLoader(tf.loadLibrary),
      ],
    ),
    QRoute(
      name: scan,
      path: '/scan',
      builder: () => sc.QRScanner(),
      middleware: [
        DefferedLoader(sc.loadLibrary),
      ],
    ),
    QRoute(
      name: history,
      path: '/history',
      builder: () => hist.HistoryPage(),
      middleware: [
        DefferedLoader(hist.loadLibrary),
      ],
    ),

  ];
}
