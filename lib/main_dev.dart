import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geomod/entry_point/app.dart';
import 'package:geomod/firebase_options.dart';
import 'package:geomod/utils/utils.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  //Just for catching errors
  // var logger = Logger();
  await runZonedGuarded(() async {
    //Loafing Production Environment Variables
    await dotenv.load(fileName: '.env.dev');

    // Only call clearSavedSettings() during testing to reset internal values.
    await Upgrader.clearSavedSettings(); // REMOVE this for release builds

    //Loading important utilities before running the app
    // await Utils.initBeforeRunApp();
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      name: 'geomod',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,

      // statusBarIconBrightness: Brightness.dark
    ));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String language_code = prefs.getString("language_code") ?? "";
    print(" language code : $language_code");
    runApp(App(locale: language_code));
  }, (error, stackTrace) {
    print(
        'runZonedGuarded: Caught error in my root zone. ${error.toString()}, in ${stackTrace.toString()}');
    Logger().d('error in main zone, in ${stackTrace.toString()}\n$error');
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}
