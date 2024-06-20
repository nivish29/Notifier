import 'dart:ui';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart' as loc;
import 'package:geomod/services/analyticService.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart' as header;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:location/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../entry_point/controller/location_controller.dart';
import '../../../entry_point/model/model.dart';
import '../../homePage/presentation/homepage.dart';
import '../../logic/background_logic.dart';

class LocationEdit extends StatefulWidget {
  int index;
  LatLng selectedLocation;
  double radius;

  LocationEdit(
      {required this.selectedLocation,
      required this.radius,
      required this.index,
      super.key});

  @override
  State<LocationEdit> createState() => _LocationEditState();
}

class _LocationEditState extends State<LocationEdit> {
  final LocationController controller = Get.find();
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  List<Data> savedLocations = [];
  late BitmapDescriptor logoMarker;

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
    // logoMarker = await controller.getSvgIcon();
    await prepareMarkerIcons();
    List<Data> dataToShow = controller.dataToShow.value;
    for (Data data in dataToShow) {
      if (data.latitude == controller.selectedLocation.latitude &&
          data.longitude == controller.selectedLocation.longitude) {
      } else {
        savedLocations.add(data);
      }
    }
    setState(() {});
    return savedLocations;
  }

  Location location = Location();

  final Map<String, Marker> _markers = {};

  double latitude = 0;
  double longitude = 0;
  GoogleMapController? _controller;
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(33.298037, 44.2879251),
    zoom: 10,
  );
  Future<void> _handleSearch() async {
    places.Prediction? p = await loc.PlacesAutocomplete.show(
        overlayBorderRadius: BorderRadius.circular(20),
        context: context,
        apiKey: 'your map key',
        onError: onError, // call the onError function below
        mode: loc.Mode.overlay,
        language: 'en', //you can set any language for search
        strictbounds: false,
        types: [],
        decoration: InputDecoration(
          hintText: 'search',
          hintStyle: TextStyle(fontWeight: FontWeight.normal),
          // fillColor: Colors.grey,
        ),
        components: [] // you can determine search for just one country
        );

    // displayPrediction(p!, homeScaffoldKey.currentState);
  }

  @override
  void dispose() {
    super.dispose();
    controller.isexpandedmap.value = false;
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

  Future<void> displayPrediction(
      places.Prediction p, ScaffoldState? currentState) async {
    places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(
        // apiKey: kGoogleApiKey,
        apiHeaders: await const header.GoogleApiHeaders().getHeaders());
    places.PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(p.placeId!);
// detail will get place details that user chose from Prediction search
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    _markers.clear(); //clear old marker and set new one
    final marker = Marker(
      markerId: const MarkerId('deliveryMarker'),
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(
        title: '',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15),
        ),
      );
    });
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

    // LocationData currentPosition = await location.getLocation();
    // latitude = currentPosition.latitude!;
    // longitude = currentPosition.longitude!;
    // final marker = Marker(
    //   markerId: const MarkerId('myLocation'),
    //   position: LatLng(latitude, longitude),
    //   infoWindow: const InfoWindow(
    //     title: 'you can add any message here',
    //   ),
    // );
    // setState(() {
    //   _markers['myLocation'] = marker;
    //   _controller?.animateCamera(
    //     CameraUpdate.newCameraPosition(
    //       CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
    //     ),
    //   );
    // });
  }

  @override
  void initState() {
    controller.selectedLocation = widget.selectedLocation;
    extractLatLngFromData();
    getCurrentLocation();
    // alreadylocation(longitude, latitude);
    controller.updateLocationName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // Analytic event
    logEventMain('navigation_editLocation');
    TextEditingController locationname = TextEditingController();
    final LocationController controller = Get.find();
    final ColorScheme col = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title:
            Text(AppLocalizations.of(context)!.location_access_select_location),
      ),
      body: Column(
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
                height: height * 0.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Builder(
                    builder: (BuildContext context) {
                      return GoogleMap(
                        onMapCreated: (GoogleMapController controller1) {
                          controller.mapController.isCompleted
                              ? null
                              : controller.mapController.complete(controller1);
                          setState(() {});
                        },
                        circles: <Circle>{
                          Circle(
                            circleId: const CircleId('currentLocationCircle'),
                            center: LatLng(controller.selectedLocation.latitude,
                                controller.selectedLocation.longitude),
                            radius: widget.radius,
                            fillColor: Colors.red.withOpacity(0.2),
                            strokeColor: Colors.red,
                            strokeWidth: 1,
                          ),
                          ...savedLocations.map((savedLocation) {
                            return Circle(
                              circleId:
                                  CircleId(savedLocation.latitude.toString()),
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
                              print(controller.selectedLocation);
                            },
                          ),
                          for (Data savedLocation in savedLocations)
                            Marker(
                              markerId:
                                  MarkerId(savedLocation.latitude.toString()),
                              // icon: logoMarker,
                              icon:
                                  logoMarkerMap.containsKey(savedLocation.name)
                                      ? logoMarkerMap[savedLocation.name] ??
                                          BitmapDescriptor.defaultMarker
                                      : logoMarkerMap["default"] ??
                                          BitmapDescriptor.defaultMarker,
                              position: LatLng(
                                savedLocation.latitude,
                                savedLocation.longitude,
                              ),
                              onTap: () {
                                print(savedLocation);
                              },
                            ),
                        },
                        onTap: (LatLng location) async {
                          bool showDialogForLocation = false;
                          String? locationNameToShowDialog;

                          // Check if the tapped location is within the radius of any saved location
                          for (Data savedLocation in savedLocations) {
                            double distanceBetweenLocations = calculateDistance(
                              savedLocation.latitude,
                              savedLocation.longitude,
                              location.latitude,
                              location.longitude,
                            );
                            if (distanceBetweenLocations <=
                                widget.radius + savedLocation.radius) {
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
                                      child: Text(AppLocalizations.of(context)!
                                          .location_access_ok),
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
                      'search',
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
                                              !controller.isexpandedmap.value;
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
                                              !controller.isexpandedmap.value;
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
          Expanded(
            child: Container(
              // height: MediaQuery.sizeOf(context).height * 0.3,
              // color: Colors.red,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                      decoration: BoxDecoration(
                          // color: Color.fromARGB(255, 234, 234, 234),
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /*Text(
                              "Location Selected",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 18),
                            ),*/
                            Obx(
                              () => Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceTint,
                                  ),
                                  Text(controller.locationName.value,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,

                                        // color: Colors.grey
                                      )),
                                ],
                              ),
                            ),
                            Divider(
                              thickness: 0.5,
                            ),
                            Text(
                              AppLocalizations.of(context)!
                                  .location_access_address,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 18),
                            ),
                            Obx(
                              () => Text(controller.locationaddress.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w200,
                                    fontSize: 12,
                                    // color: Colors.grey
                                  )),
                            ),
                            // Row(
                            //   children: [
                            //     Icon(
                            //       Icons.more_horiz_rounded,
                            //       color: Color.fromARGB(255, 6, 190, 0),
                            //     ),
                            //     SizedBox(
                            //       width: 10,
                            //     ),
                            //     Text(
                            //       "Latitude",
                            //       style: TextStyle(
                            //           fontWeight: FontWeight.w500, fontSize: 18),
                            //     ),
                            //     Spacer(),
                            //     Text("${controller.selectedLocation.latitude}",
                            //         style: TextStyle(
                            //           fontWeight: FontWeight.w500,
                            //           fontSize: 18,
                            //           // color: Colors.grey
                            //         )),
                            //   ],
                            // ),
                            // Divider(
                            //   thickness: 0.5,
                            // ),
                            // Row(
                            //   children: [
                            //     Icon(
                            //       Icons.more_vert_rounded,
                            //       color: Color.fromARGB(255, 240, 148, 0),
                            //     ),
                            //     SizedBox(
                            //       width: 10,
                            //     ),
                            //     Text(
                            //       "Longitude",
                            //       style: TextStyle(
                            //           fontWeight: FontWeight.w500, fontSize: 18),
                            //     ),
                            //     Spacer(),
                            //     Text("${controller.selectedLocation.longitude}",
                            //         style: TextStyle(
                            //           fontWeight: FontWeight.w500,
                            //           fontSize: 18,
                            //           // color: Colors.grey
                            //         )),
                            //   ],
                            // ),
                          ],
                        ),
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  // Container(
                  //   width: MediaQuery.sizeOf(context).width,
                  //   child: TextField(
                  //     decoration: InputDecoration(
                  //       filled: true,
                  //       fillColor: Colors.grey[200], // Set the background color
                  //       hintText: 'Enter Location Name', // Placeholder text
                  //
                  //       border: OutlineInputBorder(
                  //         borderRadius: BorderRadius.all(
                  //           Radius.circular(10.0),
                  //         ),
                  //         borderSide: BorderSide.none, // No borders
                  //       ),
                  //
                  //       contentPadding: EdgeInsets.symmetric(
                  //           horizontal: 16.0,
                  //           vertical: 14.0), // Padding inside the text field
                  //     ),
                  //     controller: locationname,
                  //   ),
                  // ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: const Icon(
                              Icons.close_rounded,
                            ),
                          )),
                      FilledButton(
                          onPressed: () async {
                            print(controller.selectedLocation.longitude);
                            if (await alreadylocation(
                                controller.selectedLocation.longitude,
                                controller.selectedLocation.latitude)) {
                              Navigator.pop(context, [
                                LatLng(controller.selectedLocation.latitude,
                                    controller.selectedLocation.longitude),
                                widget.radius
                              ]);
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Alert'),
                                    content: Text(
                                        'Location Already exist in 50 metre range \ncheckout archive/locations'),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: const Icon(
                              Icons.done_rounded,
                              color: Colors.white,
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(
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

class RoundedImageWithText extends StatelessWidget {
  final String imagePath;
  final String text;
  final VoidCallback onpressed;
  final bool border;

  RoundedImageWithText(
      {required this.imagePath,
      required this.text,
      required this.onpressed,
      required this.border});

  @override
  Widget build(BuildContext context) {
    final ColorScheme col = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onpressed,
      child: Container(
        decoration: BoxDecoration(
            border: border == true
                ? Border.all(
                    width: 2, color: Color.fromARGB(255, 148, 191, 255))
                : Border.all(width: 0),
            borderRadius: BorderRadius.circular(12),
            color: col.background),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,

                  width: 60, // Adjust the width as needed
                  height: 60, // Adjust the height as needed
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
