import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:geomod/ui/colors.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geomod/entry_point/controller/app_controller.dart';
import 'package:geomod/features/splash/presentation/pages/splash.dart';

class App extends StatelessWidget {
  String? locale = '';

  App({Key? key, this.locale}) : super(key: key);
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);
  final appController = Get.put(AppController());

  @override
  Widget build(BuildContext context) {
    Color seed = kolprimary;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoMod',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: seed, brightness: Brightness.light),
          useMaterial3: true,
          fontFamily: 'SF Pro Display'),
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        fontFamily: 'SF Pro Display',
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: locale != "" ? Locale(locale!) : appController.locale,
      // locale: appController.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      home: const splashscreen(),
    );
  }
}
