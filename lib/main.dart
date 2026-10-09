import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mars_launcher/pages/font_scale.dart';
import 'package:mars_launcher/pages/home/home.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:sizer/sizer.dart';
import 'package:mars_launcher/constants/method_channels.dart';
import 'package:mars_launcher/constants/global.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';


void main() async {
  print("# ---- STARTING APP MARS LAUNCHER ---- #");
  WidgetsFlutterBinding.ensureInitialized();
  await setupGetIt();

  assert(() {
    if (CLEAR_SHARED_PREFS_ON_DEBUG_START) {
      SharedPrefsManager.getInstance().then((manager) {
        manager.clearAll();
      });
    }
    return true;
  }());

  runApp(MarsLauncher());
  registerAppChangeReceiver();
}

void registerAppChangeReceiver() {
  const platform = MethodChannel(MethodChannels.notifyAppChanges);
  try {
    platform.invokeMethod('registerAppChangeReceiver');
  } catch (e) {
    print("Error registering app change receiver: $e");
  }
}

class MarsLauncher extends StatelessWidget {
  final themeManager = getIt<ThemeManager>();

  @override
  Widget build(BuildContext context) {
    print("[$runtimeType] INITIALISING");
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager.themeModeNotifier,
      builder: (context, themeMode, homeScreen) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeManager.systemUiOverlayStyle,
          child: Sizer(builder: (context, orientation, deviceType) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: themeManager.lightTheme,
                darkTheme: themeManager.darkTheme,
                themeMode: themeMode,
                builder: (context, child) => AppFontScale(child: child!),
                home: homeScreen!);
          })),
      child: const Home(),
    );
  }
}
