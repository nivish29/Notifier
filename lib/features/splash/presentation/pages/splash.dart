import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geomod/entry_point/data/sharedPref.dart';
import 'package:geomod/features/homePage/presentation/homepage.dart';
import 'package:geomod/features/login_page/presentation/pages/login_page.dart';
import 'package:geomod/features/onboarding/onboarding.dart';
import 'package:geomod/ui/colors.dart';
import 'package:get/get.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upgrader/upgrader.dart';

class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _splashscreenState();
}

class _splashscreenState extends State<splashscreen>
    with SingleTickerProviderStateMixin {
  LocationController controller1 = Get.put(LocationController());
  bool istrue = false;
  late AnimationController controller;
  late Animation<double> animation;
  Color main = kolprimary;

  // Future<void> test() async{
  //   var permissionStatus = await Permission.locationAlways.request();
  //   if(permissionStatus.isGranted){
  //     // print("Permission Granted:- testing from splash screen");
  //     Position position = await Geolocator.getCurrentPosition();
  //     controller1.selectedLocation = LatLng(position.latitude, position.longitude);
  //   }
  // }

  @override
  void initState() {
    super.initState();

    getpref();
    // test();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )
      ..forward()
      ..repeat(reverse: true);
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);

    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        istrue = true;
      }); // Prints after 1 second.
    });

    //getting preference according to onboarding screen
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (controller1.onboarding.value == true) {
        // Get.off(MyHomePage(title: 'Location_App'));
        Get.off(UpgradeAlert(
            showIgnore: false,
            showLater: false,
            
            showReleaseNotes: false,
            upgrader: Upgrader(),
           
            child: MyHomePage(title: 'Location_App')));
      } else {
        Get.off(onBoadingScreen());
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.search_ellipsis,
              color: main,
              progress: animation,
              size: 72.0,
              semanticLabel: 'Show menu',
            ),
          ),
          AnimatedScale(
            duration: const Duration(seconds: 1),
            scale: istrue ? 3 : 0,
            curve: Curves.easeOutCubic,
            child: CircleAvatar(
              maxRadius: MediaQuery.sizeOf(context).height,
              backgroundColor: main,
            ),
          ),
          Center(
            child: AnimatedScale(
              duration: const Duration(seconds: 1),
              scale: istrue ? 3 : 0,
              curve: Curves.easeOutCubic,
              child: const Icon(
                CupertinoIcons.location_solid,
                color: Color.fromARGB(255, 235, 255, 248),
              ),
            ),
          )
        ],
      ),
    );
  }
}
