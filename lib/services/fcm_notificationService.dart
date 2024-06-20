import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geomod/features/homePage/controller/home_controller.dart';
import 'package:get/get.dart';
// import 'package:location_app/ui/controller/home_controller.dart';
// import 'package:location_app/ui/location2.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../ui/homepage.dart';

class NotificationServicesFCM {
  HomeController hc = Get.put(HomeController());

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('user granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('user granted provisional permission');
    } else {
      AppSettings.openAppSettings(type: AppSettingsType.notification);
      print('user denied permission');
    }
  }

  void initLocalNotifications(BuildContext context, RemoteMessage message,
      void Function(BuildContext, int, Function) showModalFunction) async {
    var androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/location_app');

    var initializationSetting =
        InitializationSettings(android: androidInitializationSettings);
    await _flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (payload) {
      handleMessage(context, message, showModalFunction);
    });
  }

  void createNotificationChannel() {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'testing', // id
      'location channel', // title
      importance: Importance.high,
      playSound: true,
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void FirebaseInit(BuildContext context,
      void Function(BuildContext, int, Function) showModalFunction) {
    FirebaseMessaging.onMessage.listen((message) {
      print('${message.notification!.title.toString()}');
      print('${message.notification!.body.toString()}');

      if (Platform.isAndroid) {
        initLocalNotifications(context, message, showModalFunction);
        showNotification(message);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
        'High importance notification',
        importance: Importance.max);
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            channel.id.toString(), channel.name.toString(),
            channelDescription: 'Your channel description',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker');

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails);
    });
  }

  void handleMessage(BuildContext context, RemoteMessage message,
      void Function(BuildContext, int, Function) showModalFunction) async {
     int index = 0;

    if (message.data.containsKey("index")) {
      index = int.parse(message.data["index"]);
    }
    // print('index: ${index}');
    showModalFunction(context, index, hc.updateList);
  }

  void setUpInteractMessage(BuildContext context,
      void Function(BuildContext, int, Function) showModalFunction) async {
    //when app is terminated
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(context, initialMessage, showModalFunction);
    }
    //when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(context, message, showModalFunction);
    });
  }


  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    print('device token ${token}');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceToken', token??'');
    return token!;
  }

  void isTokenRefreshed() async {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      print('refresh');
    });
  }
}
