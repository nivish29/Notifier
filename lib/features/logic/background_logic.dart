import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_mute/flutter_mute.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:geomod/features/homePage/controller/home_controller.dart';
import 'package:geomod/features/logic/list_access.dart';
import 'package:geomod/services/analyticService.dart';
import 'package:geomod/services/notificationService.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:real_volume/real_volume.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocationController lc = Get.put(LocationController());
HomeController hct = Get.put(HomeController());
NotificationService notificationService = NotificationService();
bool isFetchingLocation = false;
Map<String, double> fetchingLocation1 = {};
final _locationSubscriptions = <StreamSubscription<dynamic>>[];
final _streamSubscriptions = <StreamSubscription<dynamic>>[];
bool markingNotification = false; // Variable to act as a lock
Map<String, String> ringerModeMap = {
  "0.0": "Normal",
  "1.0": "Vibrate",
  "2.0": "Silent",
};
final distance = const Distance();
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on("setAsBackgroundService").listen((event) {
      service.setAsBackgroundService();
    });
    service.on("setAsForegroundService").listen((event) {
      service.setAsForegroundService();
    });
  }

  _streamSubscriptions.add(
    userAccelerometerEvents.listen(
      (UserAccelerometerEvent event) {
        lc.axis.value = event.x;

        if ((event.x > 5 || event.y > 5 || event.z > 5) &&
            !isFetchingLocation) {
          print('Start Location Updates: ${DateTime.now()}');
          Future.delayed(const Duration(seconds: 5), () {
            startLocationUpdates();
          });
        } else if (event.x < 5 && isFetchingLocation) {
          Timer(const Duration(seconds: 30), stopLocationUpdates);
        }
      },
      onError: (e) {
        print('$e Errorrrr');
      },
      cancelOnError: true,
    ),
  );

  service.invoke('LocationData', fetchingLocation1);
}

void startLocationUpdates() {
  print('Starting location updates.');
  isFetchingLocation = true;

  LocationSettings settings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );

  _locationSubscriptions.add(
      Geolocator.getPositionStream(locationSettings: settings)
          .listen((position) async {
    List<Data> dataToShow = await gettingData();
    print(dataToShow.length);
    fetchingLocation1 = {
      "speed": (position.speed * 3.6),
      "lat": position.latitude,
      "long": position.longitude,
    };
    double latitude = position.latitude;
    double longitude = position.longitude;
    double speedMps = (position.speed * 3.6);
    bool isNotInSelectedLocation = true;
    // Analytic event
    logEventMain('background_locationFetched');
    final currentMode = await RealVolume.getRingerMode();
    for (var element in dataToShow) {
      final double distanceInMeters = distance(
        LatLng(position.latitude, position.longitude),
        LatLng(element.latitude, element.longitude),
      );
      print("Distance- $distanceInMeters");
      if (distanceInMeters < 50) {
        isNotInSelectedLocation = false;

        print("Music ${element.music}");
        if (element.ringerMode == 1.0 && currentMode != RingerMode.VIBRATE) {
          await RealVolume.setRingerMode(RingerMode.VIBRATE,
              redirectIfNeeded: true);
          print("Set Vibrate");
          // Analytic event
          logEventMain('vibrateMode_activate');
        } else if (element.ringerMode == 0.0 &&
            currentMode != RingerMode.NORMAL) {
          await RealVolume.setRingerMode(RingerMode.NORMAL,
              redirectIfNeeded: false);
          await RealVolume.setVolume(element.ring / 100.0,
              showUI: false, streamType: StreamType.RING);
          await RealVolume.setVolume(element.notiication / 100.0,
              showUI: false, streamType: StreamType.NOTIFICATION);
          print("Set Normal");
          // Analytic event
          logEventMain('normalMode_activate');
        } else if (element.ringerMode == 2.0 &&
            currentMode != RingerMode.SILENT) {
          await RealVolume.setRingerMode(RingerMode.SILENT,
              redirectIfNeeded: false);
          print("Set Silent");
          // Analytic event

          logEventMain('silentMode_activate');
        }
        int idx = dataToShow.indexOf(element);
        await showNotificationAndMarkAsShown(element, idx);

        await RealVolume.setVolume(element.music / 100.0,
            showUI: false, streamType: StreamType.MUSIC);
        await RealVolume.setVolume(element.alarm / 100.0,
            showUI: false, streamType: StreamType.ALARM);

        final ye = await RealVolume.getCurrentVol(StreamType.MUSIC);
        print("Music After change ${ye}");
        // PerfectVolumeControl.hideUI = true;
      }
      await onSignificantLocationChange(latitude, longitude, element);
    }
    if (isNotInSelectedLocation && currentMode != RingerMode.NORMAL) {
      await RealVolume.setRingerMode(RingerMode.NORMAL);
      // await RealVolume.setVolume(1, showUI: false, streamType: StreamType.RING);
      // await RealVolume.setVolume(1, showUI: false, streamType: StreamType.NOTIFICATION);
      // await RealVolume.setVolume(1, showUI: false, streamType: StreamType.MUSIC);
      // await RealVolume.setVolume(1, showUI: false, streamType: StreamType.ALARM);
    }
  }));
}

void stopLocationUpdates() {
  print('Stopping location updates.');
  isFetchingLocation = false;
  for (var element in _locationSubscriptions) {
    element.cancel();
  }
  print('Stopped Location Updates: ${DateTime.now()}');
}

Future<void> onSignificantLocationChange(
    double currentLatitude, double currentLongitude, Data locationData) async {
  double distanceInMeters = distance(LatLng(currentLatitude, currentLongitude),
      LatLng(locationData.latitude, locationData.longitude));

  print("distance (Significant) : $distanceInMeters");

  if (distanceInMeters > 50.0) {
    await clearNotificationStatusForLocation(locationData);
  }
}

Future<void> showNotificationAndMarkAsShown(
    Data locationData, int index) async {
  if (markingNotification) {
    print(
        "Notification already being marked as shown. Skipping showNotification.");
    return;
  }

  markingNotification = true;

  try {
    bool notificationAlreadyShown =
        await hasNotificationBeenShownForLocation(locationData);
    print(locationData.ringerMode);
    String ringerMode =
        ringerModeMap[locationData.ringerMode.toString()] ?? "Unknown";
    print(ringerMode);
    if (!notificationAlreadyShown) {
      print("Calling showNotification");
      try {
        await hct.sendNotification('Reached ${locationData.name}',
            "$ringerMode Mode activated.", index);
        await markNotificationAsShownForLocation(locationData);
      } catch (e) {
        print("Error sending notification $e");
      }

      // Analytic event
      logEventMain('notification_sent');

      
      print("Notification marked as shown.");
    } else {
      Logger().d('testing from notification');
      print('testing from notification');
    }
  } finally {
    markingNotification = false;
  }
}

Future<void> markNotificationAsShownForLocation(Data locationData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('setting location as marked');
  prefs.setBool(
      '${locationData.latitude}_${locationData.longitude}_shown', true);
}

Future<bool> hasNotificationBeenShownForLocation(Data locationData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(
          '${locationData.latitude}_${locationData.longitude}_shown') ??
      false;
}

Future<void> clearNotificationStatusForLocation(Data locationData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('${locationData.latitude}_${locationData.longitude}_shown');
}

Future<bool> alreadywifi(String currentwifi) async {
  List<Data> dataToShow = await gettingData();
  print("Wifi Data Fetched");
  for (var element in dataToShow) {
    if (element.isFav == currentwifi) {
      print('wifi is there');
      return false;
    }
  }
  print('wifi is not there');
  return true;
}

const double earthRadius = 6371000;
Future<bool> alreadylocation(
    double currentLongitude, double currentLatitude) async {
  List<Data> dataToShow = await gettingData();
  print("Location Data Fetched");

  for (var element in dataToShow) {
    double distance = calculateDistance(
      currentLatitude,
      currentLongitude,
      element.latitude,
      element.longitude,
    );

    if (distance <= 50.0) {
      print('Location is within 50 meters');
      return false;
    }
  }

  print('No location within 50 meters');
  return true;
}

Future<bool> alreadylocation_archive(
    double currentLongitude, double currentLatitude) async {
  List<Data> dataToShow = await gettingData_arc();
  print("Location Data Fetched");

  for (var element in dataToShow) {
    double distance = calculateDistance(
      currentLatitude,
      currentLongitude,
      element.latitude,
      element.longitude,
    );

    if (distance <= 50.0) {
      print('Location is within 50 meters');
      return false;
    }
  }

  print('No location within 50 meters');
  return true;
}

double degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

double calculateDistance(double startLatitude, double startLongitude,
    double endLatitude, double endLongitude) {
  final double distanceInMeters = distance(
    LatLng(startLatitude, startLongitude),
    LatLng(endLatitude, endLongitude),
  );
  print("Distance $distanceInMeters");
  return distanceInMeters;
}

int sethour(TimeOfDay time1, int minutes) {
  int hour;
  hour = time1.hour;

  if (time1.minute + minutes > 59) {
    hour++;
    if (hour == 24) hour = 0;
  }

  return hour;
}

int setminute(TimeOfDay time1, int minutes) {
  int minute;
  minute = time1.minute + minutes;

  if (time1.minute + minutes > 59) {
    minute = (time1.minute + minutes) % 60;
  }

  return minute;
}

bool isCurrentTimeInRange(
    int startHour, int startMinute, int endHour, int endMinute) {
  DateTime now = DateTime.now();
  DateTime startTime =
      DateTime(now.year, now.month, now.day, startHour, startMinute);
  DateTime endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

  // If start time is greater than end time, adjust the end time to the next day
  if (startTime.isAfter(endTime)) {
    endTime = endTime.add(Duration(days: 1));
  }

  return now.isAfter(startTime) && now.isBefore(endTime);
}
