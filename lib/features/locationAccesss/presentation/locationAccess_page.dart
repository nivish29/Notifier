import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places/flutter_google_places.dart' as loc;
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:geomod/features/homePage/presentation/homepage.dart';
import 'package:geomod/features/logic/background_logic.dart';
import 'package:geomod/features/logic/list_access.dart';
import 'package:geomod/services/notificationService.dart';
import 'package:geomod/ui/widgets/ringerMode.dart';
import 'package:geomod/ui/widgets/roundedImageWithText.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart' as header;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:location/location.dart';
import 'package:real_volume/real_volume.dart';
import 'package:uni_links/uni_links.dart';
import 'package:upgrader/upgrader.dart';

import '../../../services/analyticService.dart';

// import '../utils/analyticService.dart';
// import 'locationedit.dart';

class LocationAccess extends StatefulWidget {
  const LocationAccess({super.key});

  @override
  State<LocationAccess> createState() => _LocationAccessState();
}

bool _initialUriIsHandled = false;

class _LocationAccessState extends State<LocationAccess>
    with WidgetsBindingObserver {
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  late BitmapDescriptor logoMarker;
  List<Data> savedLocations = [];
  LocationController controller = Get.put(LocationController());
  TextEditingController nameController = TextEditingController();
  Location location = Location();

  double latitude = 0;
  double selectedRingerMode = 0.0;
  double value1 = 0.0;
  double longitude = 0;
  late Map<String, BitmapDescriptor> logoMarkerMap;
  Future<void> prepareMarkerIcons() async {
    try {
      List<BitmapDescriptor> icons = await controller.getSvgIconList();

      print('icons length : ${icons.length}');

      // Assign names to icons
      List<String> iconNames = [
        "default",
        "Home",
        "School",
        "College",
        "Work",
        "Place for worship",
        "Gym"
      ];

      // Create the map
      logoMarkerMap = Map.fromIterables(iconNames, icons);
    } catch (e) {
      print('error from location access list: $e');
    }
  }

  Future<List<Data>> extractLatLngFromData() async {
    await prepareMarkerIcons();
    // logoMarker = await controller.getSvgIcon();
    // print('logoMarkerMap:');
    // logoMarkerMap.forEach((key, value) {
    //   print('$key: $value');
    // });

    // print('home found: ${logoMarkerMap}');
    List<Data> dataToShow = controller.dataToShow.value;
    print('data to show in the location access page: ${dataToShow.length}');
    for (Data data in dataToShow) {
      savedLocations.add(data);
    }
    setState(() {});
    print("Location already :${savedLocations.length}");
    return savedLocations;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final dndPermission = await RealVolume.isPermissionGranted();
      print("Permission $dndPermission");
      if (dndPermission!) {
        controller.isdnd.value = true;
      } else {
        controller.isdnd.value = false;
      }
    }
  }
late GoogleMapController _mapController;
  Future<void> _handleSearch() async {
    final places.GoogleMapsPlaces find = places.GoogleMapsPlaces(
        apiKey: 'AIzaSyBdpHK36b_FWVj9KIDXfkJx3RUzGnbCcOU');
    places.Prediction? p = await loc.PlacesAutocomplete.show(
      overlayBorderRadius: BorderRadius.circular(20),
      context: context,
      apiKey: 'AIzaSyBdpHK36b_FWVj9KIDXfkJx3RUzGnbCcOU',
      onError: onError, // call the onError function below
      mode: loc.Mode.overlay,
      language: 'en', //you can set any language for search
      strictbounds: false,
      types: [],
      decoration: const InputDecoration(
        hintText: 'search',
        hintStyle: TextStyle(
          fontWeight: FontWeight.normal,
        ),
        // fillColor: Colors.grey,
      ),
      components: [], // you can determine search for just one country
    );
    if (p != null) {
      // Get place details using the place ID
      try {
        final response = await find.getDetailsByPlaceId(p.placeId!);

        final places.PlacesDetailsResponse detail = response;
        final double lat = detail.result.geometry!.location.lat;
        final double lng = detail.result.geometry!.location.lng;

        // Do something with the coordinates
        print('Latitude: $lat, Longitude: $lng');
        // Example: Add marker on a map
        LatLng position = LatLng(lat, lng);
        setState(() {
          controller.selectedLocation = position;
        });
         _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(controller.selectedLocation.latitude, controller.selectedLocation.longitude)));
      
        // Add your functionality here to use the coordinates, e.g., updating the mapha
      } catch (e) {
        print('Error fetching place details: $e');
      }
    }
  }

  void onError(places.PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Message',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData currentPosition = await location.getLocation();
    latitude = currentPosition.latitude!;
    longitude = currentPosition.longitude!;

    markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: LatLng(latitude,
            longitude), // Adjust the position to where you want to show your app icon
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed, // Customize marker color if needed
        ),
        onTap: () {
          // Handle marker tap
          print('App icon marker tapped');
        },
      ),
    );

    // hct.showLoading.value = false;
  }

  void updateCircleRadius(double newRadius) {
    setState(() {
      // Find the circle associated with the marker representing the current location
      circles.removeWhere(
          (circle) => circle.circleId == CircleId('currentLocationCircle'));
      print('after issue ${controller.radius.value}');
      circles.add(
        Circle(
          circleId: CircleId('currentLocationCircle'),
          center: LatLng(latitude, longitude),
          radius: controller.radius.value,
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red,
          strokeWidth: 1,
        ),
      );
    });
  }

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

  @override
  void initState() {
    // hct.showLoading.value = true;
    extractLatLngFromData();
    WidgetsBinding.instance.addObserver(this);
    // alreadylocation(longitude, latitude);
    _handleIncomingLinks();
    _handleInitialUri();
    // hct.showLoading.value=false;
    (null);
    super.initState();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = !_initialUriIsHandled ? await getInitialUri() : null;
      print("Uri :$uri");
      if (uri == null) {
        print('no initial uri');
        initializeRingVolume();
        controller.updateLocationName();
        getCurrentLocation();
        markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(
                controller.selectedLocation.latitude,
                controller.selectedLocation
                    .longitude), // Adjust the position to where you want to show your app icon
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed, // Customize marker color if needed
            ),
            onTap: () {
              // Handle marker tap
              print('App icon marker tapped');
            },
          ),
        );
      } else {
        _initialUriIsHandled = true; // Mark initial URI as handled
        Map<String, String> queryParameters = uri.queryParameters;
        print("uri");
        String name = queryParameters['name'] ?? '';
        double mediaVolume =
            double.tryParse(queryParameters['media_volume'] ?? '') ?? 0.0;
        double alarmVolume =
            double.tryParse(queryParameters['alarm_volume'] ?? '') ?? 0.0;
        double ringtoneVolume =
            double.tryParse(queryParameters['ringtone_volume'] ?? '') ?? 0.0;
        double notificationVolume =
            double.tryParse(queryParameters['notification_volume'] ?? '') ??
                0.0;
        double alatitude =
            double.tryParse(queryParameters['latitude'] ?? '') ?? 0.0;
        double alongitude =
            double.tryParse(queryParameters['longitude'] ?? '') ?? 0.0;
        double ringerMode =
            double.tryParse(queryParameters['ringer_mode'] ?? '') ?? 0.0;
        print("Media $mediaVolume");
        print("alarm $alarmVolume");
        print("ringtone $ringtoneVolume");
        print("notification $notificationVolume");
        print("lattitude $alatitude");

        setState(() {
          nameController.text = name;
          controller.ringermode.value = ringerMode;
          controller.music.value = mediaVolume;
          controller.alarm.value = alarmVolume;
          controller.ring.value = ringtoneVolume;
          controller.notfication.value = notificationVolume;
          controller.selectedLocation = LatLng(alatitude, alongitude);
          controller.updateLocationName();
        });
      }
      if (!mounted) return;
    } on PlatformException {
      // Platform messages may fail but we ignore the exception
      print('failed to get initial uri');
    } on FormatException catch (err) {
      if (!mounted) return;
      print('malformed initial uri');
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.clear();
    controller.isexpandedmap.value = false;
    _sub?.cancel();
    nameController.text = '';
  }

  Future<void> initializeRingVolume() async {
    double? currentRingVolume = await RealVolume.getCurrentVol(StreamType.RING);
    double? currentAlarmVolume =
        await RealVolume.getCurrentVol(StreamType.ALARM);
    double? currentNotificationVolume =
        await RealVolume.getCurrentVol(StreamType.NOTIFICATION);
    double? currentMusicVolume =
        await RealVolume.getCurrentVol(StreamType.MUSIC);
    setState(() {
      controller.ring.value = currentRingVolume! * 100;
      controller.alarm.value = currentAlarmVolume! * 100;
      controller.notfication.value = currentNotificationVolume! * 100;
      controller.music.value = currentMusicVolume! * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Analytic event
    logEventMain('navigation_addLocation');
    final height = MediaQuery.sizeOf(context).height;
    final LocationController controller = Get.find();
    final ColorScheme col = Theme.of(context).colorScheme;
    MapType maptype = MapType.normal;
    // bool isExpanded = false;
    return UpgradeAlert(
      dialogStyle: UpgradeDialogStyle.material,
      showIgnore: false,
      showLater: false,
      showReleaseNotes: false,
      upgrader: Upgrader(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.location_access_select_location,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: double.infinity,
                    height: height * 0.45,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Builder(
                        builder: (BuildContext context) {
                          return GoogleMap(
                            onMapCreated: (GoogleMapController controller1) {
                              controller.mapController.isCompleted
                                  ? null
                                  : controller.mapController
                                      .complete(controller1);
                                _mapController = controller1;
                                _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(controller.selectedLocation.latitude, controller.selectedLocation.longitude)));
                            },
                            circles: <Circle>{
                              Circle(
                                circleId:
                                    const CircleId('currentLocationCircle'),
                                center: LatLng(
                                    controller.selectedLocation.latitude,
                                    controller.selectedLocation.longitude),
                                radius: controller.radius.value,
                                fillColor: Colors.red.withOpacity(0.2),
                                strokeColor: Colors.red,
                                strokeWidth: 1,
                              ),
                              ...savedLocations.map((savedLocation) {
                                return Circle(
                                  circleId: CircleId(
                                      savedLocation.latitude.toString()),
                                  center: LatLng(savedLocation.latitude,
                                      savedLocation.longitude),
                                  radius: savedLocation.radius,
                                  fillColor: Colors.blue.withOpacity(0.2),
                                  strokeColor: Colors.blue,
                                  strokeWidth: 1,
                                );
                              }),
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapType: controller.maptype.value.mp,
                            compassEnabled: true,
                            mapToolbarEnabled: false,
                            initialCameraPosition: CameraPosition(
                              target: controller.selectedLocation,
                              zoom: 14.4746,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('Selected_Location'),
                                position: controller.selectedLocation,
                                onTap: () {
                                  // Handle tap on current location marker
                                  print('tap on map location');
                                  print(controller.selectedLocation);
                                },
                              ),
                              for (Data savedLocation in savedLocations)
                                Marker(
                                  markerId: MarkerId(
                                      savedLocation.latitude.toString()),
                                  // icon: logoMarker,
                                  icon: logoMarkerMap
                                          .containsKey(savedLocation.name)
                                      ? logoMarkerMap[savedLocation.name] ??
                                          BitmapDescriptor.defaultMarker
                                      : logoMarkerMap["default"] ??
                                          BitmapDescriptor.defaultMarker,
                                  position: LatLng(
                                    savedLocation.latitude,
                                    savedLocation.longitude,
                                  ),
                                  onTap: () {
                                    print('location: ${savedLocation}');
                                  },
                                ),
                            },
                            onTap: (LatLng location) async {
                              hct.prev_latitude_radius.value =
                                  hct.latitude_radius.value;
                              hct.prev_longitude_radius.value =
                                  hct.longitude_radius.value;
                              hct.latitude_radius.value = location.latitude;
                              hct.longitude_radius.value = location.longitude;
                              bool showDialogForLocation = false;
                              String? locationNameToShowDialog;

                              // Check if the tapped location is within the radius of any saved location
                              for (Data savedLocation in savedLocations) {
                                double distanceBetweenLocations =
                                    calculateDistance(
                                  savedLocation.latitude,
                                  savedLocation.longitude,
                                  location.latitude,
                                  location.longitude,
                                );
                                if (distanceBetweenLocations <=
                                    controller.radius.value +
                                        savedLocation.radius) {
                                  hct.latitude_radius.value =
                                      hct.prev_latitude_radius.value;
                                  hct.longitude_radius.value =
                                      hct.prev_longitude_radius.value;
                                  showDialogForLocation = true;
                                  locationNameToShowDialog = savedLocation.name;
                                  break; // Exit loop if overlap found
                                }
                              }

                              // Show dialog if necessary
                              if (showDialogForLocation) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Alert'),
                                      content: Text(
                                          'You are within the radius of $locationNameToShowDialog'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('OK'),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // Update the selectedLocation if the dialog is not shown
                                setState(() {
                                  circles.clear();
                                  controller.selectedLocation = location;
                                });
                                await controller.updateLocationName();
                                alreadylocation(
                                  controller.selectedLocation.longitude,
                                  controller.selectedLocation.latitude,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top:
                        10, // you can change place of search bar any where on the map
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: col.background),
                        onPressed: _handleSearch,
                        child: Text(
                          AppLocalizations.of(context)!.location_access_search,
                          style: TextStyle(color: col.surfaceTint),
                        )),
                  ),
                  Positioned(
                    right: 17,
                    top: 60,
                    child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          setState(() {
                            controller.isexpandedmap.value =
                                !controller.isexpandedmap.value;
                          });
                        },
                        icon: Icon(
                          Icons.layers_outlined,
                          color: Colors.black54,
                        )),
                  ),
                  if (controller.isexpandedmap.value)
                    Positioned(
                      top: 120,
                      left: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: col.background.withOpacity(0.4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      RoundedImageWithText(
                                          imagePath: 'lib/assets/satellite.jpg',
                                          text: 'Satellite',
                                          onpressed: () {
                                            setState(() {
                                              controller.maptype.value.mp =
                                                  MapType.satellite;
                                              controller.isexpandedmap.value =
                                                  !controller
                                                      .isexpandedmap.value;
                                            });
                                          },
                                          border: controller.maptype.value.mp ==
                                              MapType.satellite),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      RoundedImageWithText(
                                          imagePath: 'lib/assets/terrain.jpg',
                                          text: 'Terrain',
                                          onpressed: () {
                                            setState(() {
                                              controller.maptype.value.mp =
                                                  MapType.terrain;
                                              controller.isexpandedmap.value =
                                                  !controller
                                                      .isexpandedmap.value;
                                            });
                                          },
                                          border: controller.maptype.value.mp ==
                                              MapType.terrain),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  RoundedImageWithText(
                                      imagePath: 'lib/assets/default.jpg',
                                      text: 'Normal',
                                      onpressed: () {
                                        setState(() {
                                          controller.maptype.value.mp =
                                              MapType.normal;
                                          controller.isexpandedmap.value =
                                              !controller.isexpandedmap.value;
                                        });
                                      },
                                      border: controller.maptype.value.mp ==
                                          MapType.normal)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              Container(
                // height: MediaQuery.sizeOf(context).height * 0.3,
                // color: Colors.red,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            // color: col.surfaceVariant,
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: col.surfaceTint,
                                  ),
                                  Obx(
                                    () => Text(controller.locationName.value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          // color: Colors.grey
                                        )),
                                  ),
                                ],
                              ),
                              Divider(
                                thickness: 0.5,
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .location_access_location_radius,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Obx(
                                () => SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight:
                                          8, // Increase the track height for better visibility
                                      overlayColor: Colors
                                          .transparent, // Hide overlay color
                                    ),
                                    child: Slider(
                                      min: 50, // Set the minimum value
                                      max: 250, // Set the maximum value
                                      divisions:
                                          4, // Number of divisions between min and max
                                      value: controller.radius.value,
                                      onChanged: (double newValue) {
                                        controller.radius.value =
                                            newValue.roundToDouble();
                                        print(
                                            'radius found: ${controller.radius.value}');

                                        updateCircleRadius(
                                            newValue.roundToDouble());
                                        // bool showDialogForLocation = false;
                                        controller.showDialog.value = false;
                                        String? locationNameToShowDialog;

                                        // Check if the tapped location is within the radius of any saved location
                                        for (Data savedLocation
                                            in savedLocations) {
                                          double distanceBetweenLocations =
                                              calculateDistance(
                                                  savedLocation.latitude,
                                                  savedLocation.longitude,
                                                  hct.latitude_radius.value,
                                                  hct.longitude_radius.value
                                                  // location.latitude,
                                                  // location.longitude,
                                                  );
                                          if (distanceBetweenLocations <=
                                              controller.radius.value +
                                                  savedLocation.radius) {
                                            controller.showDialog.value = true;
                                            locationNameToShowDialog =
                                                savedLocation.name;
                                            print(
                                                'still issue: ${controller.radius.value}');
                                            controller.radius.value = 50;
                                            // controller.radius.value -
                                            //     newValue.roundToDouble();
                                            controller.radius.refresh();
                                            print(
                                                'controller.radius = ${controller.radius.value}');
                                            updateCircleRadius(
                                                newValue.roundToDouble() -
                                                    controller.radius.value);
                                            break; // Exit loop if overlap found
                                          }
                                        }

                                        // Show dialog if necessary
                                        if (controller.showDialog.value) {
                                          // controller.showDialog.value = false;
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Alert'),
                                                content: Text(
                                                    'You are within the radius of $locationNameToShowDialog'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: Text('OK'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                      label: '${controller.radius.value.round()} ' +
                                          AppLocalizations.of(context)!
                                              .location_access_location_radius_meter,
                                      onChangeEnd: (double newValue) {
                                        double roundedValue =
                                            (newValue / 50).round() * 50;
                                        if (controller.showDialog.value) {
                                          controller.radius.value =
                                              roundedValue - 50;
                                          print('testing');
                                        } else {
                                          controller.radius.value =
                                              roundedValue;
                                        }

                                        // roundedValue = 50;
                                        // controller.radius.value = 50;
                                        updateCircleRadius(roundedValue);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppLocalizations.of(context)!
                                    .location_access_ringer_mode,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              Ringermode(),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.settings_outlined),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Container(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Icon(
                                                Icons.close,
                                                color: col.surfaceVariant,
                                              ))
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: col.surfaceTint,
                                          ),
                                          Expanded(
                                            child: Text(
                                                controller
                                                    .locationaddress.value,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 4,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,

                                                  // color: Colors.grey
                                                )),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .location_access_location_name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: col.onSurface),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        width: MediaQuery.sizeOf(context).width,
                                        child: DropdownButtonFormField<String>(
                                          value: nameController.text.isNotEmpty
                                              ? nameController.text
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          decoration: InputDecoration(
                                            filled: true,
                                            hintText: AppLocalizations.of(
                                                    context)!
                                                .location_access_enter_location,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20.0),
                                              ),
                                              borderSide:
                                                  BorderSide.none, // No borders
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                              vertical: 12.0,
                                            ),
                                          ),
                                          onChanged: (newValue) {
                                            if (newValue ==
                                                AppLocalizations.of(context)!
                                                    .location_access_add_manually) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  TextEditingController
                                                      textController =
                                                      TextEditingController();
                                                  return AlertDialog(
                                                    title: Text(AppLocalizations
                                                            .of(context)!
                                                        .location_access_enter_location_name),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        TextField(
                                                          controller:
                                                              textController,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: AppLocalizations
                                                                    .of(context)!
                                                                .location_access_location_name,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () {
                                                          // Cancel button pressed
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .archive_page_cancel),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          if (textController
                                                              .text
                                                              .isNotEmpty) {
                                                            setState(() {
                                                              nameController
                                                                      .text =
                                                                  textController
                                                                      .text;
                                                            });
                                                          }
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
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
                                            if (nameController
                                                    .text.isNotEmpty &&
                                                // ![
                                                //   'Add Manually',
                                                //   'Home',
                                                //   'School',
                                                //   'College',
                                                //   'Work',
                                                //   'Place for Worship',
                                                //   'Gym'
                                                // ].contains(nameController.text)
                                                ![
                                                  AppLocalizations.of(context)!
                                                      .location_access_add_manually,
                                                  AppLocalizations.of(context)!
                                                      .location_access_home,
                                                  AppLocalizations.of(context)!
                                                      .location_access_school,
                                                  AppLocalizations.of(context)!
                                                      .location_access_college,
                                                  AppLocalizations.of(context)!
                                                      .location_access_work,
                                                  AppLocalizations.of(context)!
                                                      .location_access_worship,
                                                  AppLocalizations.of(context)!
                                                      .location_access_gym,
                                                ].contains(nameController.text))
                                              nameController.text,
                                            // 'Add Manually',
                                            // 'Home',
                                            // 'School',
                                            // 'College',
                                            // 'Work',
                                            // 'Place for Worship',
                                            // 'Gym',
                                            AppLocalizations.of(context)!
                                                .location_access_add_manually,
                                            AppLocalizations.of(context)!
                                                .location_access_home,
                                            AppLocalizations.of(context)!
                                                .location_access_school,
                                            AppLocalizations.of(context)!
                                                .location_access_college,
                                            AppLocalizations.of(context)!
                                                .location_access_work,
                                            AppLocalizations.of(context)!
                                                .location_access_worship,
                                            AppLocalizations.of(context)!
                                                .location_access_gym,
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
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.volume_up_outlined,
                                            color: col.surfaceTint,
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .location_access_media,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: col.onSurface),
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width,
                                          child: Slider(
                                            max: 100,
                                            divisions: 100,
                                            value: controller.music.value,
                                            label: controller.music.value
                                                .round()
                                                .toString(),
                                            onChanged: (double newValue) {
                                              setState(() {
                                                controller.music.value =
                                                    newValue.roundToDouble();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.alarm_outlined,
                                            color: col.surfaceTint,
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .location_access_alarm,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: col.onSurface),
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width,
                                          child: Slider(
                                            max: 100,
                                            divisions: 100,
                                            value: controller.alarm.value,
                                            label: controller.alarm.value
                                                .round()
                                                .toString(),
                                            onChanged: (double newValue) {
                                              setState(() {
                                                controller.alarm.value =
                                                    newValue.roundToDouble();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => IgnorePointer(
                                          ignoring:
                                              controller.ringermode.value !=
                                                  0.0,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.music_note_outlined,
                                                color: controller
                                                            .ringermode.value !=
                                                        0.0
                                                    ? Colors.grey
                                                    : col.surfaceTint,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .location_access_ringtone,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: controller.ringermode
                                                              .value !=
                                                          0.0
                                                      ? Colors.grey
                                                      : col.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => IgnorePointer(
                                          ignoring:
                                              controller.ringermode.value !=
                                                  0.0,
                                          child: SizedBox(
                                            width: MediaQuery.sizeOf(context)
                                                .width,
                                            child: Slider(
                                              max: 100,
                                              divisions: 100,
                                              value: controller.ring.value,
                                              label: controller.ring.value
                                                  .round()
                                                  .toString(),
                                              onChanged: (double newValue) {
                                                setState(() {
                                                  controller.ring.value =
                                                      newValue.roundToDouble();
                                                });
                                              },
                                              activeColor:
                                                  controller.ringermode.value !=
                                                          0.0
                                                      ? Colors.grey
                                                      : col.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => IgnorePointer(
                                          ignoring:
                                              controller.ringermode.value !=
                                                  0.0,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.notifications_outlined,
                                                color: controller
                                                            .ringermode.value !=
                                                        0.0
                                                    ? Colors.grey
                                                    : col.surfaceTint,
                                              ),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .location_access_notification,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: controller.ringermode
                                                              .value !=
                                                          0.0
                                                      ? Colors.grey
                                                      : col.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => IgnorePointer(
                                          ignoring:
                                              controller.ringermode.value !=
                                                  0.0,
                                          child: SizedBox(
                                            width: MediaQuery.sizeOf(context)
                                                .width,
                                            child: Slider(
                                              max: 100,
                                              divisions: 100,
                                              value: controller
                                                  .notfication.value
                                                  .toDouble(),
                                              label: controller.notfication
                                                  .round()
                                                  .toString(),
                                              onChanged: (double newValue) {
                                                setState(() {
                                                  controller.notfication.value =
                                                      newValue.roundToDouble();
                                                });
                                              },
                                              activeColor:
                                                  controller.ringermode.value !=
                                                          0.0
                                                      ? Colors.grey
                                                      : col.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      /*const SizedBox(height: 16),
                                          const Text(
                                            "Ringer Mode",
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 16),
                                          Ringermode(),
                                          SizedBox(
                                            height: 15,
                                          ),*/
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FilledButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .location_access_done)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      label: Text(
                          AppLocalizations.of(context)!.home_page_more_setting),
                    ),
                    FilledButton(
                        onPressed: () async {
                          print(controller.selectedLocation.longitude);
                          if (nameController.text.isEmpty) {
                            nameController.text = controller.locationName.value;
                          }
                          if (await alreadylocation(
                                  controller.selectedLocation.longitude,
                                  controller.selectedLocation.latitude) &&
                              await alreadylocation_archive(
                                  controller.selectedLocation.longitude,
                                  controller.selectedLocation.latitude)) {
                            if (controller.ringermode.value == 2.0 &&
                                !controller.isdnd.value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please grant DND permissions'),
                                  action: SnackBarAction(
                                    label: 'Grant',
                                    onPressed: () {
                                      RealVolume.openDoNotDisturbSettings();
                                    },
                                  ),
                                ),
                              );
                            } else {
                              controller.dataToShow.value.add(Data(
                                isFav: false,
                                name: nameController.text,
                                // name: controller.locationName,
                                latitude: controller.selectedLocation.latitude,
                                longitude:
                                    controller.selectedLocation.longitude,
                                radius: controller.radius.value,
                                music: controller.music.value,
                                alarm: controller.alarm.value,
                                notiication: controller.notfication.value,
                                ring: controller.ring.value,
                                ringerMode: controller.ringermode.value,
                                timeHour: -1,
                                timeMinute: -1,
                                timeHour_end: -1,
                                timeMinute_end: -1,
                              ));
                              Data lastAdded = controller.dataToShow.value.last;
                              if ((double.parse(latitude.toStringAsFixed(3)) -
                                              double.parse(lastAdded.latitude
                                                  .toStringAsFixed(3)) ==
                                          0) &&
                                      (double.parse(longitude
                                                  .toStringAsFixed(3)) -
                                              double.parse(lastAdded.longitude
                                                  .toStringAsFixed(3)) ==
                                          0) ||
                                  (DateTime.now().hour - lastAdded.timeHour ==
                                          0 &&
                                      DateTime.now().minute -
                                              lastAdded.timeMinute ==
                                          0)) {
                                if (lastAdded.ringerMode == 0.0) {
                                  await RealVolume.setRingerMode(
                                      RingerMode.NORMAL,
                                      redirectIfNeeded: false);
                                  await RealVolume.setVolume(
                                      lastAdded.ring / 100.0,
                                      showUI: true,
                                      streamType: StreamType.RING);
                                  await RealVolume.setVolume(
                                      lastAdded.notiication / 100.0,
                                      showUI: true,
                                      streamType: StreamType.NOTIFICATION);
                                  print("Set Normal");
                                } else if (lastAdded.ringerMode == 1.0) {
                                  await RealVolume.setRingerMode(
                                      RingerMode.VIBRATE,
                                      redirectIfNeeded: false);
                                  print("Set Vibrate");
                                } else if (lastAdded.ringerMode == 2.0) {
                                  await RealVolume.setRingerMode(
                                      RingerMode.SILENT,
                                      redirectIfNeeded: false);

                                  print("Set Silent");
                                }
                                await RealVolume.setVolume(
                                    lastAdded.music / 100.0,
                                    showUI: true,
                                    streamType: StreamType.MUSIC);
                                await RealVolume.setVolume(
                                    lastAdded.alarm / 100.0,
                                    showUI: true,
                                    streamType: StreamType.ALARM);
                                // PerfectVolumeControl.hideUI = true;
                              }
                              //Analytic event
                              logEventMain('new_location');
                              controller.update();
                              storingData(controller.dataToShow.value);
                              Navigator.of(context).pop();
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Alert'),
                                  content: Text(
                                      'Location Already exist in range.\nPlease Select choose Other Location'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        // style: ElevatedButton.styleFrom(
                        //     backgroundColor: Color.fromARGB(255, 0, 46, 231)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)!
                                .home_page_save_location,
                            // color: Colors.white,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => MyHomePage(
      title: 'hello1',
    ),
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

class Ringermode extends StatefulWidget {
  LocationController controller = Get.put(LocationController());
  @override
  _RingermodeState createState() => _RingermodeState();
}

class _RingermodeState extends State<Ringermode> {
  LocationController controller = Get.put(LocationController());
  double volumevalue = 0.0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme col = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        selectedIcon: Icon(Icons.done_rounded),
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
        selected: <int>{controller.ringermode.value.toInt()},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            print(
                "controller.ringermode.value : ${controller.ringermode.value}");
            controller.ringermode.value = newSelection.first.toDouble();
          });
        },
      ),
    );
  }
}

class ExpandedOption extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  ExpandedOption({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // return IconButton.filledTonal(onPressed: onPressed, icon: Icon(iconData));
    return TextButton(onPressed: onPressed, child: Text(title));
  }
}
