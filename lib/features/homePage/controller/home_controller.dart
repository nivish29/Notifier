import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:latlong2/latlong.dart';
// import 'package:location_app/controller/location_controller.dart';
// import 'package:location_app/logic/background_logic.dart';
// import 'package:location_app/logic/list_access.dart';
// import 'package:location_app/model/model.dart';
// import 'package:location_app/utils/fcm_notificationService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_volume/real_volume.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

class HomeController extends GetxController {
  LocationController controller = Get.put(LocationController());
  // NotificationServicesFCM nsf = NotificationServicesFCM();
  // FirebaseMessaging messaging = FirebaseMessaging.instance;
  var index = 0.obs;
  var latitude_radius=0.0.obs;
  var longitude_radius=0.0.obs;
  var prev_latitude_radius=0.0.obs;
  var prev_longitude_radius=0.0.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var isLoading = false.obs;
  var deviceToken = ''.obs;
  var location_key = 0.obs;
  var showLoading = false.obs;
  // var _isControllerActive = true.obs;

  //  Future<String> getDeviceToken() async {
  //   String? token = await messaging.getToken();
  //   // deviceToken.value = token??'';
  //   return token!;
  // }

  @override
  void onInit() {
    print("current device token from home controller ${deviceToken.value}");
  //  String tk = await getDeviceToken();
    // deviceToken.value = tk;
    // print('token from home controller ${deviceToken.value}');
    super.onInit();
  }

  @override
  void onClose() {
    // Set the flag to false when the controller is closed
    // _isControllerActive.value = false;
    super.onClose();
  }

  int StringToIndex(double latitude, double longitude, String name) {
    return controller.dataToShow.indexWhere((element) =>
        element.latitude == latitude &&
        element.longitude == longitude &&
        element.name == name);
  }

  void test(){
    print('testing token ${deviceToken.value}');
  }

  void updateList() {
    controller.dataToShow.refresh();
    // setState(() {});
  }


  Future<void> sendNotification(String title, String body, int idx) async {

     final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('deviceToken');

    print('token from send notification function ${token}');

    var data = {
     'to': token,
      'priority': 'high',
      'notification': {
        'title': title,
        'body': body,
        "android_channel_id": "testing"
      },
      'data': {'index': idx}
    };

    print("data is $data");

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'key=AAAADmeu3Fw:APA91bG4rVqxBOQ-cDAnrRnBClNXYQ8ErHyD-n9lGRU8zPIJvSKJsVD4DajDoDUvvpH1_49zU9NuaIMgKr2Ghn0KObl5BGgcPK3OqC_KM8K1AOOY3JIEFBk3aaBRkeXC_dVeTWPT0tRu'
      },
    );
  }

}
