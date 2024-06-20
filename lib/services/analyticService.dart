import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_core/firebase_core.dart';

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> logEventMain(String eventName) async {
  await Firebase.initializeApp();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceUUID = '';
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceUUID = androidInfo.androidId;
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceUUID = iosInfo.identifierForVendor;
  }

  analytics.setAnalyticsCollectionEnabled(true);
  // print('testing event name $eventName');
  analytics.logEvent(
    name: eventName,
    parameters: {
      'device_uuid': deviceUUID,
    },
  );
}
