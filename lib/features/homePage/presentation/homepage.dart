import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:geomod/features/archives/presentation/archives.dart';
import 'package:geomod/features/homePage/controller/home_controller.dart';
import 'package:geomod/features/logic/background_logic.dart';
import 'package:geomod/features/logic/list_access.dart';
import 'package:geomod/services/analyticService.dart';
import 'package:geomod/services/fcm_notificationService.dart';
import 'package:geomod/services/notificationService.dart';
import 'package:geomod/ui/widgets/customDialog.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/i_awesome_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:real_volume/real_volume.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uni_links/uni_links.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui/widgets/dnd_dialog.dart';
import '../../locationAccesss/presentation/locationAccess_page.dart';
import '../../locationAccesss/presentation/locationEdit.dart';

bool _initialUriIsHandled = false;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  TextEditingController textEditingController = TextEditingController();
  double latitude = 0;
  double longitude = 0;
  double speedMps = 0;
  double _value = 30;
  double normalVolume = 0.0;
  TimeOfDay? time;
  TimeOfDay? time_end;
  int? hour_end;
  int? minute_end;
  LocationController controller = Get.put(LocationController());
  NotificationService service = NotificationService();

  bool backgroundServiceActive = false;

  fetchingData({bool isFromInit = false}) async {
    print('Location permission requesting');
    var permissionStatus = await Permission.locationAlways.request();
    print('Location permissionStatus is : '
        'isDenied = ${permissionStatus.isDenied}, '
        'isGranted = ${permissionStatus.isGranted}, '
        'isRestricted = ${permissionStatus.isRestricted},'
        'isPermanentlyDenied = ${permissionStatus.isPermanentlyDenied}, '
        'isLimited = ${permissionStatus.isLimited}, '
        'isProvisional = ${permissionStatus.isProvisional}');
    if (!permissionStatus.isGranted) {
      print('Location permissionStatus is Not Granted : '
          'isDenied = ${permissionStatus.isDenied}, '
          'isGranted = ${permissionStatus.isGranted}, '
          'isRestricted = ${permissionStatus.isRestricted},'
          'isPermanentlyDenied = ${permissionStatus.isPermanentlyDenied}, '
          'isLimited = ${permissionStatus.isLimited}, '
          'isProvisional = ${permissionStatus.isProvisional}');
      if (!isFromInit) {
        openAppSettings();
      }
    } else {
      // controller.toshow.value = false;
      print('Location permissionStatus is Granted: '
          'isDenied = ${permissionStatus.isDenied}, '
          'isGranted = ${permissionStatus.isGranted}, '
          'isRestricted = ${permissionStatus.isRestricted},'
          'isPermanentlyDenied = ${permissionStatus.isPermanentlyDenied}, '
          'isLimited = ${permissionStatus.isLimited}, '
          'isProvisional = ${permissionStatus.isProvisional}');
      Position position = await Geolocator.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
      controller.selectedLocation = LatLng(latitude, longitude);
      controller.toshow.value = true;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;

        // controller.selectedLocation = LatLng(latitude, longitude);
      });
      print('current latitude when issue raised ${latitude}');
      if (!isFromInit) {
        Navigator.of(context).push(_createRoute());
      }
    }
    FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  List<double>? _userAccelerometerValues;
  Uri? _initialUri;
  Uri? _latestUri;
  Object? _err;

  StreamSubscription? _sub;

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      print('got uri: $uri');
      setState(() {
        _latestUri = uri;
        _err = null;
      });
    }, onError: (Object err) {
      if (!mounted) return;
      print('got err: $err');
      setState(() {
        _latestUri = null;
        if (err is FormatException) {
          _err = err;
        } else {
          _err = null;
        }
      });
    });
  }

  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      print('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LocationAccess()));
        }
        if (!mounted) return;
        setState(() => _initialUri = uri);
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        print('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  HomeController homeController = Get.put(HomeController());
  Future<void> getDeviceTokenMain() async {
    String tk = await notificationServicesFCM.getDeviceToken();
    homeController.deviceToken.value = tk;
  }

  Future<void> getData() async {
    controller.dataToShow.value = await gettingData();
    controller.dataToShow_fav.value = await gettingData_fav();
    controller.dataToShow_arc.value = await gettingData_arc();
    // controller.toshow.value = true;
    await fetchingData(isFromInit: true);
    // controller.toshow.value = false;
  }

  Future<void> test() async {
    print('12');
    var permissionStatus = await Permission.locationAlways.request();
    print('123');
    if (permissionStatus.isGranted) {
      // print("Permission Granted:- testing from splash screen");
      controller.toshow.value = false;
      print('1234');
      Position position = await Geolocator.getCurrentPosition();
      print('12345');
      controller.selectedLocation =
          LatLng(position.latitude, position.longitude);
      print('123456');
      controller.toshow.value = true;
    } else {
      controller.toshow.value = true;
    }
  }

  NotificationServicesFCM notificationServicesFCM = NotificationServicesFCM();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  @override
  void initState() {
    //  controller.toshow.value = false;
    test();
    getData();
    //  controller.toshow.value = true;
    WidgetsFlutterBinding.ensureInitialized();
    analytics.setAnalyticsCollectionEnabled(true);
    notificationServicesFCM.requestNotificationPermission();
    notificationServicesFCM.createNotificationChannel();
    notificationServicesFCM.FirebaseInit(
      context,
      (BuildContext context, int index, Function updateList) {
        showCustomModalBottomSheet(context, index, updateList);
      },
    );

    getDeviceTokenMain().then((_) {
      print("Device token from ${homeController.deviceToken.value}");

      notificationServicesFCM.setUpInteractMessage(
        context,
        (BuildContext context, int index, Function updateList) {
          showCustomModalBottomSheet(context, index, updateList);
        },
      );
    });
    // dndCheck(); // was removed earlier
    WidgetsBinding.instance.addObserver(this);
    _handleIncomingLinks();
    _handleInitialUri();
    super.initState();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always) {
        controller.fetchingLoader.value = false;
        if (!controller.onboarding.value) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DndDialog();
            },
          );
        }
        try {
          bool stat = await FlutterBackgroundService().isRunning();
          print("Status  $stat");
          if (FlutterBackgroundService().isRunning() == false) {
            FlutterBackgroundService().configure(
              androidConfiguration: AndroidConfiguration(
                onStart: onStart,
                autoStart: true,
                isForegroundMode: true,
              ),
              iosConfiguration: IosConfiguration(),
            );
          }
        } catch (e) {
          print("Service Not Running $e");
        }
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });
        print("Got Location");
        print("dnd value ${controller.onboarding.value}");
      } else {
        controller.fetchingLoader.value = true;
      }
    }
  }

  @override
  void dispose() {
    print("background mode");
    FlutterBackgroundService().invoke('setAsBackgroundService');
    _sub?.cancel();
    super.dispose();
  }

  int selectedOption = 0;
  Widget alertBoxData(int index, Function updateListCallback) {
    TextEditingController nameController = TextEditingController();
    nameController.text = controller.dataToShow.value[index].name.toString();
    double ring = controller.dataToShow.value[index].ring;
    double music = controller.dataToShow.value[index].music;
    double alarm = controller.dataToShow.value[index].alarm;
    double notification = controller.dataToShow.value[index].notiication;
    double radius = controller.dataToShow.value[index].radius;
    double ringerMode = controller.dataToShow.value[index].ringerMode;
    print(">>>>>>>");
    print(alarm);
    print(music);

    void shareSettings(double latitude, double longitude) {
      // Convert data to JSON format
      Map<String, String> params = {
        "name": nameController.text,
        "media_volume": music.toString(),
        "alarm_volume": alarm.toString(),
        "radius": radius.toString(),
        "ringtone_volume": ring.toString(),
        "notification_volume": notification.toString(),
        "ringer_mode": ringerMode.toString(),
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
      };

      var uri = Uri.https('picosoftsolutions.com', '/settings');
      uri = uri.replace(queryParameters: params);
      // Encode JSON data in the deep link
      // String deepLink = ("https://ringerRadius/settings");

      // Share the deep link via the share_plus package
      // Share.share('testing url \n\n $uri');
      Share.share(uri.toString(), subject: 'Share Settings');
    }

    // void shareSettings(double latitude, double longitude) {
    //   // Convert data to JSON format
    //   try {
    //     Map<String, String> params = {
    //       "name": nameController.text,
    //       "media_volume": music.toString(),
    //       "alarm_volume": alarm.toString(),
    //       "radius": radius.toString(),
    //       "ringtone_volume": ring.toString(),
    //       "notification_volume": notification.toString(),
    //       "ringer_mode": ringerMode.toString(),
    //       "latitude": latitude.toString(),
    //       "longitude": longitude.toString(),
    //     };

    //     // Construct deep link URL
    //     var uri = Uri.https('geomod', '/settings', params);
    //     // String deepLink = uri.toString();
    //     String deepLink =
    //         "https://geomod/settings?name=Home&media_volume=93.30000000000001&alarm_volume=100.0&radius=50.0&ringtone_volume=87.5&notification_volume=100.0&ringer_mode=0.0&latitude=23.190217851888633&longitude=72.63702470809221";
    //     // Share the clickable link via the share_plus package
    //     Share.share(deepLink, subject: 'Settings Deep Link');
    //   } catch (e) {
    //     print('error: ' + e.toString());
    //   }
    // }

    LatLng selectedLocation = LatLng(
        controller.dataToShow.value[index].latitude,
        controller.dataToShow.value[index].longitude);
    LatLng temp = LatLng(controller.dataToShow.value[index].latitude,
        controller.dataToShow.value[index].longitude);
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        final ColorScheme col = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              color: col.surface
              // color: Colors.white,
              ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      AppLocalizations.of(context)!.home_page_bottomsheet_name,
                      style: TextStyle(color: col.onSurface),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    child: DropdownButtonFormField<String>(
                      value: nameController.text.isNotEmpty
                          ? nameController.text
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      decoration: InputDecoration(
                        filled: true,
                        hintText: AppLocalizations.of(context)!
                            .location_access_enter_location,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20.0),
                          ),
                          borderSide: BorderSide.none, // No borders
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                      ),
                      onChanged: (newValue) {
                        if (newValue == "Add Manually") {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController textController =
                                  TextEditingController();
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .location_access_enter_location_name),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextField(
                                      controller: textController,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!
                                            .location_access_location_name,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      // Cancel button pressed
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .archive_page_cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (textController.text.isNotEmpty) {
                                        setState(() {
                                          nameController.text =
                                              textController.text;
                                        });
                                      }
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .location_access_ok),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          setState(() {
                            nameController.text = newValue!;
                          });
                        }
                      },
                      items: <String>[
                        if (nameController.text.isNotEmpty &&
                            ![
                              'Add Manually',
                              'Home',
                              'School',
                              'College',
                              'Work',
                              'Place for Worship',
                              'Gym'
                            ].contains(nameController.text))
                          nameController.text,
                        'Add Manually',
                        'Home',
                        'School',
                        'College',
                        'Work',
                        'Place for Worship',
                        'Gym',
                      ].map<DropdownMenuItem<String>>(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                        child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LocationEdit(
                                        radius: radius,
                                        selectedLocation: selectedLocation,
                                        index: index)),
                              );
                              temp = result[0];
                              radius = result[1];
                              print(selectedLocation.longitude);
                            },
                            icon: const Icon(Icons.edit_location_alt_outlined,
                                size: 17),
                            label: Text(AppLocalizations.of(context)!
                                .home_page_bottomsheet_edit_location))),
                  ),
                ),
                Obx(() {
                  final isFav = controller.dataToShow.value[index].isFav;
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 12, right: 15.0, top: 1),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!isFav) {
                            controller.dataToShow.value[index].isFav = true;
                            controller.isfavourite.value++;
                            // Analytic event
                            logEventMain('location_fav');
                          } else {
                            controller.dataToShow.value[index].isFav = false;
                            controller.isfavourite.value--;
                            // Analytic event
                            logEventMain('location_unfav');
                          }
                          storingData(controller.dataToShow.value);
                        });
                        controller.update();
                        setState(() {});
                        print(controller.isfavourite);
                      },
                      child: Icon(
                        size: 28,
                        isFav ? CupertinoIcons.star_fill : CupertinoIcons.star,
                        color: isFav ? Colors.amber : null,
                        // Add shadows if needed
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    shareSettings(
                        selectedLocation.latitude, selectedLocation.longitude);
                    // Analytic event
                    logEventMain('location_shared');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 4),
                    child: Icon(Icons.share, size: 28),
                  ),
                )
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    color: col.surfaceTint,
                  ),
                  Text(
                    "Location Radius",
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: col.onSurface),
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight:
                        8, // Increase the track height for better visibility
                    overlayColor: Colors.transparent, // Hide overlay color
                  ),
                  child: Slider(
                    min: 50, // Set the minimum value
                    max: 250, // Set the maximum value
                    divisions: 4, // Number of divisions between min and max
                    value: radius,
                    onChanged: (double newValue) {
                      setState(() {
                        radius = newValue.roundToDouble();
                      });
                    },
                    label: '${radius.round()} meters',
                    onChangeEnd: (double newValue) {
                      // Round the value to the nearest allowed marker value
                      double roundedValue = (newValue / 50).round() * 50;
                      setState(() {
                        radius = roundedValue;
                      });
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.volume_up_outlined,
                    color: col.surfaceTint,
                  ),
                  Text(
                    AppLocalizations.of(context)!.location_access_media,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: col.onSurface),
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Slider(
                  max: 100,
                  divisions: 100,
                  value: music,
                  label: music.round().toString(),
                  onChanged: (double newValue) {
                    setState(() {
                      music = newValue.roundToDouble();
                    });
                  },
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.alarm_outlined,
                    color: col.surfaceTint,
                  ),
                  Text(
                    AppLocalizations.of(context)!.location_access_alarm,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: col.onSurface),
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Slider(
                  max: 100,
                  divisions: 100,
                  value: alarm,
                  label: alarm.round().toString(),
                  onChanged: (double newValue) {
                    setState(() {
                      alarm = newValue.roundToDouble();
                    });
                  },
                ),
              ),
              IgnorePointer(
                ignoring: ringerMode != 0.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      color: ringerMode != 0.0 ? Colors.grey : col.surfaceTint,
                    ),
                    Text(
                      AppLocalizations.of(context)!.location_access_ringtone,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: ringerMode != 0.0 ? Colors.grey : col.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: ringerMode != 0.0,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Slider(
                    max: 100,
                    divisions: 100,
                    value: ring,
                    label: ring.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        ring = newValue.roundToDouble();
                      });
                    },
                    activeColor: ringerMode != 0.0 ? Colors.grey : col.primary,
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: ringerMode != 0.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: ringerMode != 0.0 ? Colors.grey : col.surfaceTint,
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .location_access_notification,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: ringerMode != 0.0 ? Colors.grey : col.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: ringerMode != 0.0,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Slider(
                    max: 100,
                    divisions: 100,
                    value: notification,
                    label: notification.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        notification = newValue.roundToDouble();
                      });
                    },
                    activeColor: ringerMode != 0.0 ? Colors.grey : col.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.location_access_ringer_mode,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    ButtonSegment<int>(
                        value: 0,
                        label: Text(
                          AppLocalizations.of(context)!
                              .location_access_ringer_mode_normal,
                        ),
                        icon: Icon(Icons.notifications_active_outlined)),
                    ButtonSegment<int>(
                        value: 1,
                        label: Text(
                          AppLocalizations.of(context)!
                              .location_access_ringer_mode_vibrate,
                        ),
                        icon: Icon(Icons.vibration_outlined)),
                    ButtonSegment<int>(
                        value: 2,
                        label: Text(
                          AppLocalizations.of(context)!
                              .location_access_ringer_mode_silent,
                        ),
                        icon: Icon(Icons.notifications_off_outlined)),
                  ],
                  selected: <int>{ringerMode.toInt()},
                  onSelectionChanged: (Set<int> newSelection) {
                    // if (newSelection.contains(2) &&
                    //     Permission.accessNotificationPolicy.status.isGranted ==
                    //         false) {
                    //   showDialog(
                    //     context: context,
                    //     builder: (BuildContext context) {
                    //       return AlertDialog(
                    //         title: Text('DND Permission Required'),
                    //         content: Text(
                    //             'Please grant Do Not Disturb permissions to continue.'),
                    //         actions: [
                    //           TextButton(
                    //             child: Text('Cancel'),
                    //             onPressed: () {
                    //               Navigator.of(context).pop();
                    //             },
                    //           ),
                    //           TextButton(
                    //             child: Text('Grant'),
                    //             onPressed: () {
                    //               Navigator.of(context).pop();
                    //               RealVolume.openDoNotDisturbSettings();
                    //             },
                    //           ),
                    //         ],
                    //       );
                    //     },
                    //   );
                    // }
                    setState(() {
                      ringerMode = newSelection.first.toDouble();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: col.surfaceVariant,
                    child: IconButton(
                        onPressed: () {
                          _showDialog(context, index, closeBottomSheet: () {
                            Navigator.of(context)
                                .pop(); // Closes the bottom sheet
                          });

                          setState(() {});
                        },
                        icon: const Icon(CupertinoIcons.archivebox)),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                      onPressed: () {
                        time = null;
                        Navigator.pop(context, 'Cancel');
                      },
                      child: Text(
                        AppLocalizations.of(context)!.archive_page_cancel,
                      )),
                  const SizedBox(
                    width: 20,
                  ),
                  FilledButton(
                    // style: ElevatedButton.styleFrom(
                    //     backgroundColor: blue, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (ringerMode == 2.0 && !controller.isdnd.value) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('DND Permission Required'),
                              content: Text(
                                  'Please grant Do Not Disturb permissions to continue.'),
                              actions: [
                                
                                TextButton(
                                  child: Text('Grant'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    RealVolume.openDoNotDisturbSettings();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        selectedLocation = temp;
                        print("ALarm $alarm");
                        controller.dataToShow.value[index] = Data(
                          isFav: controller.dataToShow.value[index].isFav,
                          name: nameController.text,
                          latitude: selectedLocation.latitude,
                          longitude: selectedLocation.longitude,
                          radius: radius,
                          music: music,
                          alarm: alarm,
                          notiication: notification,
                          ring: ring,
                          ringerMode: ringerMode,
                          timeHour: time?.hour == null ? -1 : time!.hour,
                          timeMinute: time?.minute == null ? -1 : time!.minute,
                          timeHour_end: hour_end ?? -1,
                          timeMinute_end: minute_end ?? -1,
                        );
                        time = null;
                        await storingData(controller.dataToShow.value);
                        // startLocationUpdates();
                        updateListCallback();

                        if (calculateDistance(
                                latitude,
                                longitude,
                                controller.dataToShow.value[index].latitude,
                                controller.dataToShow.value[index].longitude) <
                            controller.radius.value) {
                          if (controller.dataToShow.value[index].ringerMode ==
                              1.0) {
                            await RealVolume.setRingerMode(RingerMode.VIBRATE,
                                redirectIfNeeded: false);
                            // FlutterMute.setRingerMode(RingerMode.Vibrate);
                            print("Set Vibrate");
                          } else if (controller
                                  .dataToShow.value[index].ringerMode ==
                              0.0) {
                            // FlutterMute.setRingerMode(RingerMode.Normal);
                            await RealVolume.setRingerMode(RingerMode.NORMAL,
                                redirectIfNeeded: false);
                            await RealVolume.setVolume(
                                controller.dataToShow.value[index].ring / 100.0,
                                showUI: true,
                                streamType: StreamType.RING);
                            await RealVolume.setVolume(
                                controller.dataToShow.value[index].notiication /
                                    100.0,
                                showUI: true,
                                streamType: StreamType.NOTIFICATION);

                            print("Set Normal");
                          } else if (controller
                                  .dataToShow.value[index].ringerMode ==
                              2.0) {
                            await RealVolume.setRingerMode(RingerMode.SILENT,
                                redirectIfNeeded: false);
                            // FlutterMute.setRingerMode(RingerMode.Silent)
                            print("Set Silent");
                          }
                          await RealVolume.setVolume(
                              controller.dataToShow.value[index].music / 100.0,
                              showUI: true,
                              streamType: StreamType.MUSIC);
                          await RealVolume.setVolume(
                              controller.dataToShow.value[index].alarm / 100.0,
                              showUI: true,
                              streamType: StreamType.ALARM);
                        }
                        //Analytic event
                        logEventMain('update_location');
                        Navigator.pop(context);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!
                        .home_page_bottomsheet_update),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void updateList() {
    controller.dataToShow.refresh();
    setState(() {});
  }

  void _showDialog(BuildContext context, int index,
      {VoidCallback? closeBottomSheet}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.home_page_confirm),
          content: Text(AppLocalizations.of(context)!
              .home_page_bottomsheet_confirm_proceed),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.home_page_no),
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.home_page_yes),
              onPressed: () {
                setState(() async {
                  controller.dataToShow_arc.value.add(
                    Data(
                      isFav: controller.dataToShow.value[index].isFav,
                      name: controller.dataToShow.value[index].name,
                      // name: controller.locationName,
                      latitude: controller.dataToShow.value[index].latitude,
                      longitude: controller.dataToShow.value[index].longitude,
                      radius: controller.dataToShow.value[index].radius,
                      music: controller.dataToShow.value[index].music,
                      alarm: controller.dataToShow.value[index].alarm,
                      notiication:
                          controller.dataToShow.value[index].notiication,
                      ring: controller.dataToShow.value[index].ring,
                      ringerMode: controller.dataToShow.value[index].ringerMode,
                      timeHour: controller.dataToShow.value[index].timeHour,
                      timeMinute: controller.dataToShow.value[index].timeMinute,
                      timeHour_end:
                          controller.dataToShow.value[index].timeHour_end,
                      timeMinute_end:
                          controller.dataToShow.value[index].timeMinute_end,
                    ),
                  );
                  // Analytic event
                  logEventMain('location_archived');
                  controller.update();
                  storingData_arc(controller.dataToShow_arc.value);
                  await RealVolume.setRingerMode(RingerMode.NORMAL);
                  // FlutterMute.setRingerMode(RingerMode.Normal);

                  Navigator.pop(context, true);

                  Navigator.pop(context);

                  setState(() {
                    controller.dataToShow.value.removeAt(index);
                    storingData(controller.dataToShow.value);
                  });
                  print(controller.dataToShow.length);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Location Archived',
                      style: TextStyle(),
                    ),
                  ));
                });
                // Call the callback if provided
              },
            ),
          ],
        );
      },
    );
  }

  void showCustomModalBottomSheet(
      BuildContext context, int index, Function updateList) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) => alertBoxData(index, updateList),
    );
  }

  @override
  Widget build(BuildContext context) {
    homeController.test();
    return GetBuilder<LocationController>(builder: (_) {
      LocationController controller = Get.put(LocationController());
      final ColorScheme col = Theme.of(context).colorScheme;
      Map<String, IconData> mp = {
        "0": Icons.notifications_active_outlined,
        "1": Icons.vibration_outlined,
        "2": Icons.notifications_off_outlined,
      };
      return Scaffold(
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: col.primaryContainer),
                child: Text(
                  AppLocalizations.of(context)!.home_page_settings,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                ),
              ),
              ListTile(
                leading: Icon(Icons.archive),
                title: Text(AppLocalizations.of(context)!.home_page_archive),
                onTap: () {
                  Get.to(const ArchivesPage());
                  // Update the state of the app.
                  // ...
                },
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text(
                    AppLocalizations.of(context)!.home_page_Change_language),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CustomDialog(
                        text:
                            AppLocalizations.of(context)!.select_your_language),
                  );
                  // Update the state of the app.
                  // ...
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.home_page_appbar,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.add),
            //   onPressed: () async {
            //     // homeController.sendNotification('Nihal', 'Testing on click');

            //   },
            // ),
            controller.dataToShow.value.isEmpty &&
                    controller.dataToShow_fav.value.isEmpty
                ? SizedBox()
                : controller.toshow.value == true
                    ? IconButton(
                        onPressed: () async {
                          // logEventMain('testing via appbar');

                          controller.selectedLocation =
                              LatLng(latitude, longitude);
                          await controller.updateLocationName();
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const LocationAccess(),
                          //   ),
                          // ).then((value) => () async {});
                          Navigator.of(context).push(_createRoute());
                        },
                        icon: const Icon(
                          Icons.add_location_outlined,
                          size: 28,
                        ))
                    : SizedBox()
          ],
        ),
        body: Center(
          child: controller.dataToShow.value.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: latitude == 0 && longitude == 0
                          ? fetchingData
                          : () {
                              controller.selectedLocation =
                                  LatLng(latitude, longitude);
                              Navigator.of(context).push(_createRoute());
                            },
                      child: Obx(
                        () {
                          // Check the condition in the controller and show widgets accordingly
                          if (controller.fetchingLoader.value) {
                            return Card(
                              color: col.surfaceVariant,
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        'Background location required',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                          'Please choose "allow all the time" in the next screen, this permission is required for real time location fetching, place alerts and volume automations.'),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Spacer(),
                                          Text(
                                            'Give access',
                                            style: TextStyle(
                                                color: col.onSurfaceVariant),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Icon(
                              Icons.add_circle,
                              size: 40,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                )
              : Obx(
                  () {
                    // Check the condition in the controller and show widgets accordingly
                    if (controller.fetchingLoader.value) {
                      return GestureDetector(
                        onTap: fetchingData,
                        child: Card(
                          color: col.surfaceVariant,
                          child: SizedBox(
                            height: 215,
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Background location required',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      'Please choose "allow all the time" in the next screen, this permission is required for real time location fetching, place alerts and volume automations.'),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Spacer(),
                                      Text(
                                        'Give access',
                                        style: TextStyle(
                                            color: col.onSurfaceVariant),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          Obx(
                            () =>
                                controller.dataToShow.any((data) => data.isFav)
                                    ? Container(
                                        // height:
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 15.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Favourites',
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 110,
                                                child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: controller
                                                        .dataToShow
                                                        .value
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .isFav ==
                                                              true
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          5.0,
                                                                      vertical:
                                                                          8),
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap: () {
                                                                  showCupertinoModalPopup<
                                                                      void>(
                                                                    barrierColor: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.5),
                                                                    context:
                                                                        context,
                                                                    builder: (BuildContext
                                                                            context) =>
                                                                        CupertinoActionSheet(
                                                                      title:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Select an action',
                                                                          style: TextStyle(
                                                                              fontSize: 16,
                                                                              color: col.onBackground),
                                                                        ),
                                                                      ),
                                                                      // message: const Text('Would you like to unarchive/delete'),
                                                                      actions: <CupertinoActionSheetAction>[
                                                                        CupertinoActionSheetAction(
                                                                          isDefaultAction:
                                                                              true,
                                                                          onPressed:
                                                                              () {
                                                                            controller.dataToShow.value[index].isFav =
                                                                                false;
                                                                            controller.isfavourite.value--;
                                                                            setState(() {
                                                                              storingData(controller.dataToShow.value);
                                                                            });

                                                                            controller.update();
                                                                            Navigator.pop(context);
                                                                            // Analytic event
                                                                            logEventMain('location_unfav');
                                                                          },
                                                                          child:
                                                                              const Text('Unfavourite'),
                                                                        ),
                                                                        CupertinoActionSheetAction(
                                                                          onPressed:
                                                                              () async {
                                                                            Navigator.pop(context);
                                                                            showModalBottomSheet(
                                                                              backgroundColor: Colors.white,
                                                                              useSafeArea: true,
                                                                              isScrollControlled: true,
                                                                              context: context,
                                                                              builder: (BuildContext context) => alertBoxData(index, () => updateList()),
                                                                            );
                                                                            Position
                                                                                position =
                                                                                await Geolocator.getCurrentPosition();
                                                                            setState(() {
                                                                              latitude = position.latitude;
                                                                              longitude = position.longitude;
                                                                            });
                                                                          },
                                                                          child:
                                                                              const Text('Edit'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                                child: SizedBox(
                                                                  width: 70,
                                                                  child: Column(
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            70,
                                                                        width:
                                                                            70,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(50),
                                                                            color: col.secondary),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            controller.dataToShow.value[index].name[0].toUpperCase() ??
                                                                                'H',
                                                                            style: TextStyle(
                                                                                fontSize: 30,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: col.onSecondary),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        controller
                                                                            .dataToShow
                                                                            .value[index]
                                                                            .name,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : SizedBox();
                                                    }),
                                              )
                                            ],
                                          ),
                                        ),
                                      )
                                    : SizedBox(),
                          ),
                          controller.toshow.value == false
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .home_page_location,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                          Expanded(
                            child: controller.toshow.value == false
                                ? Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount:
                                        controller.dataToShow.value.length,
                                    itemBuilder: (context, index) {
                                      final item = controller
                                          .dataToShow.value[index].latitude;
                                      return InkWell(
                                        onTap: () {
                                          // print(
                                          //     'index from name : -${homeController.StringToIndex(controller.dataToShow.value[index].latitude, controller.dataToShow.value[index].longitude, controller.dataToShow.value[index].name.toString())}');
                                          showCustomModalBottomSheet(context,
                                              index, () => updateList());

                                          // showModalBottomSheet(
                                          //   backgroundColor: Colors.white,
                                          //   useSafeArea: true,
                                          //   isScrollControlled: true,
                                          //   context: context,
                                          //   builder: (BuildContext context) =>
                                          //       alertBoxData(
                                          //           index, () => updateList()),
                                          // );
                                        },
                                        child: Dismissible(
                                          confirmDismiss: (direction) async {
                                            return showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .home_page_confirm),
                                                  content: Text(AppLocalizations
                                                          .of(context)!
                                                      .home_page_confirm_message),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .home_page_no),
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, false);
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .home_page_yes),
                                                      onPressed: () {
                                                        setState(() async {
                                                          controller
                                                              .dataToShow_arc
                                                              .value
                                                              .add(
                                                            Data(
                                                              isFav: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .isFav,
                                                              name: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .name,
                                                              // name: controller.locationName,
                                                              latitude:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .latitude,
                                                              longitude:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .longitude,
                                                              radius: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .radius,
                                                              music: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .music,
                                                              alarm: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .alarm,
                                                              notiication:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .notiication,
                                                              ring: controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .ring,
                                                              ringerMode:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .ringerMode,
                                                              timeHour:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .timeHour,
                                                              timeMinute:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .timeMinute,
                                                              timeHour_end:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .timeHour_end,
                                                              timeMinute_end:
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .timeMinute_end,
                                                            ),
                                                          );
                                                          print(
                                                              "location Archive");
                                                          await RealVolume
                                                              .setRingerMode(
                                                                  RingerMode
                                                                      .NORMAL);
                                                          // FlutterMute.setRingerMode(
                                                          //     RingerMode.Normal);

                                                          controller.update();
                                                          storingData_arc(
                                                              controller
                                                                  .dataToShow_arc
                                                                  .value);

                                                          controller
                                                              .dataToShow.value
                                                              .removeAt(index);
                                                          storingData(controller
                                                              .dataToShow
                                                              .value);
                                                          print(controller
                                                              .dataToShow
                                                              .length);
                                                          Navigator.pop(
                                                              context, true);
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          key: Key(item.toString()),
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color: col.errorContainer,
                                            ),
                                            child: Center(
                                                child: Icon(
                                              Icons.archive_rounded,
                                              color: col.onErrorContainer,
                                            )),
                                          ),
                                          onDismissed: (direction) {
                                            setState(() {
                                              controller.dataToShow.value
                                                  .removeAt(index);
                                              storingData(
                                                  controller.dataToShow.value);
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                    col.surfaceVariant,
                                                content: Text(
                                                  'Location Archived',
                                                  style: TextStyle(
                                                      color:
                                                          col.onSurfaceVariant),
                                                ),
                                                // action: SnackBarAction(
                                                //   textColor: col.primary,
                                                //   label: 'OK',
                                                //   onPressed: () {
                                                //     // Code to execute.
                                                //   },
                                                // ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Card(
                                              margin: EdgeInsets.zero,
                                              elevation: 0.1,
                                              color: col.secondaryContainer
                                                  .withOpacity(0.5),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 10),
                                                child: SizedBox(
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                          .width,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Stack(
                                                        alignment: Alignment
                                                            .bottomRight,
                                                        children: [
                                                          CircleAvatar(
                                                            maxRadius: 25,
                                                            backgroundColor:
                                                                col.surface,
                                                            child: /*Text(
                                                  controller.dataToShow.value[index]
                                                      .name[0]
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight: FontWeight.bold),
                                                ),*/
                                                                Icon(
                                                              mp[controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .ringerMode
                                                                  .round()
                                                                  .toString()],
                                                              color: col
                                                                  .surfaceTint,
                                                            ),
                                                          ),
                                                          Obx(
                                                            () {
                                                              return CircleAvatar(
                                                                maxRadius: 6,
                                                                backgroundColor: calculateDistance(
                                                                            latitude,
                                                                            longitude,
                                                                            controller.dataToShow.value[index].latitude,
                                                                            controller.dataToShow.value[index].longitude) <
                                                                        50
                                                                    ? Colors.green
                                                                    : Colors.orange,
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.5,
                                                            child: Text(
                                                              controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 6,
                                                                        right:
                                                                            8,
                                                                        bottom:
                                                                            6),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .volume_up_outlined,
                                                                      color: col
                                                                          .surfaceTint,
                                                                    ),
                                                                    Text(
                                                                      "${controller.dataToShow.value[index].music.round().toString()}%",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight: FontWeight
                                                                              .normal,
                                                                          color:
                                                                              col.surfaceTint),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0,
                                                                    vertical:
                                                                        6),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .alarm_outlined,
                                                                      color: col
                                                                          .surfaceTint,
                                                                    ),
                                                                    Text(
                                                                      "${controller.dataToShow.value[index].alarm.round().toString()}%",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight: FontWeight
                                                                              .normal,
                                                                          color:
                                                                              col.surfaceTint),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      Spacer(),
                                                      controller
                                                                  .dataToShow
                                                                  .value[index]
                                                                  .isFav ==
                                                              false
                                                          ? SizedBox()
                                                          : Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          10.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  controller
                                                                      .dataToShow
                                                                      .value[
                                                                          index]
                                                                      .isFav = false;
                                                                  controller
                                                                      .isfavourite
                                                                      .value--;
                                                                  setState(() {
                                                                    storingData(controller
                                                                        .dataToShow
                                                                        .value);
                                                                  });
                                                                  // Analytic event
                                                                  logEventMain(
                                                                      'location_unfav');
                                                                  controller
                                                                      .update();
                                                                  print(controller
                                                                      .isfavourite);
                                                                },
                                                                child: Icon(
                                                                  size: 25,
                                                                  CupertinoIcons
                                                                      .star_fill,
                                                                  shadows: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.5),
                                                                      spreadRadius:
                                                                          3,
                                                                      blurRadius:
                                                                          3,
                                                                      offset: Offset(
                                                                          0,
                                                                          1), // changes position of shadow
                                                                    ),
                                                                  ],
                                                                  color: Colors
                                                                      .amber,
                                                                ),
                                                              ),
                                                            ),
                                                      /*IconButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  backgroundColor: Colors.white,
                                                  useSafeArea: true,
                                                  isScrollControlled: true,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          alertBoxData(
                                                              index,
                                                              () =>
                                                                  updateList()),
                                                );
                                              },
                                              icon: Icon(
                                                mp[controller
                                                    .dataToShow
                                                    .value[index]
                                                    .ringerMode
                                                    .round()
                                                    .toString()],
                                                color:
                                                calculateDistance(latitude, longitude, controller.dataToShow.value[index].latitude,
                                                    controller.dataToShow.value[index].longitude) < 50 ? Colors.green :
                                                col.surfaceTint,
                                                  size: 28
                                              ))*/
                                                      // icon: const Icon(Icons.more_vert))
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    }
                  },
                ),
        ),
      );
    });
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const LocationAccess(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
