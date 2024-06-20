import 'dart:ui';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geomod/entry_point/data/sharedPref.dart';
import 'package:geomod/features/homePage/presentation/homepage.dart';
import 'package:geomod/features/signin_page/presentation/pages/signin_page.dart';
import 'package:geomod/services/analyticService.dart';
import 'package:geomod/ui/widgets/customDialog.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../../utils/analyticService.dart';

class onBoadingScreen extends StatefulWidget {
  const onBoadingScreen({super.key});

  @override
  State<onBoadingScreen> createState() => _onBoadingScreenState();
}

class _onBoadingScreenState extends State<onBoadingScreen> {
  bool isanimate = false;
  int _count = 0;
  Color _color = Colors.green;
  late final SharedPreferences prefs;
  @override
  void initState() {
    super.initState();
    // getpref();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _color = Colors.white;

        // isanimate = true;
      });
      showDialog(
        context: context,
        builder: (context) =>
            CustomDialog(text: AppLocalizations.of(context)!.select_your_language),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Analytic event
    logEventMain('navigation_onboarding');
    setState(() {});
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: AnimatedContainer(
        height: height,
        width: width,
        curve: Curves.easeIn,
        duration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: isanimate ? Alignment.topLeft : Alignment.topRight,
            radius: 2.0,
            colors: isanimate
                ? [
                    const Color.fromARGB(255, 3, 91, 244),
                    Colors.lightBlue,
                    const Color.fromARGB(255, 121, 188, 220),
                    Color.fromARGB(255, 234, 234, 234)
                    // Colors.white,
                  ]
                : [
                    Color.fromARGB(255, 91, 3, 244),
                    const Color.fromARGB(255, 107, 3, 244),
                    Color.fromARGB(255, 176, 121, 220),
                    const Color.fromARGB(255, 235, 235, 235),
                  ],
          ),
        ),
        child: Column(children: [
          SizedBox(
            height: height * 0.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  curve: Curves.easeInOut,
                  top: isanimate ? height * 0.1 + 50 : height * 0.1,
                  left: isanimate ? (width / 2 - 300) : (width / 2 - 100),
                  child: AnimatedOpacity(
                    opacity: isanimate ? 0.0 : 0.5,
                    duration: Duration(milliseconds: 500),
                    child: Container(
                        // color: Colors.white,
                        width: width,
                        // height: height * 0.5,
                        // color: Colors.white,
                        child: Icon(
                          CupertinoIcons.building_2_fill,
                          size: 250,
                        )),
                  ),
                  duration: Duration(milliseconds: 1000),
                ),
                AnimatedPositioned(
                  curve: Curves.easeInOut,
                  top: isanimate ? height * 0.1 + 50 : height * 0.1,
                  left: isanimate ? (width / 2 - 300) : (width / 2 - 100),
                  child: AnimatedOpacity(
                    opacity: isanimate ? 0.5 : 0.0,
                    duration: Duration(milliseconds: 1000),
                    child: Container(
                        // color: Colors.white,
                        width: width,
                        // height: height * 0.5,
                        // color: Colors.white,
                        child: Icon(
                          CupertinoIcons.home,
                          size: 250,
                        )),
                  ),
                  duration: Duration(milliseconds: 1000),
                ),
                AnimatedPositioned(
                  curve: Curves.bounceInOut,
                  top: height * 0.1,

                  // top: isanimate? height*0.2:height*0.2+50,
                  // left: isanimate? width/2-200:(width/2-200),
                  child: Container(
                      // color: Colors.white,
                      width: width,
                      // height: height * 0.5,
                      // color: Colors.white,
                      child: Center(
                          child: Image.asset(
                        'lib/assets/ji.png',
                        fit: BoxFit.fill,
                      ))),
                  duration: Duration(milliseconds: 500),
                ),
                AnimatedPositioned(
                  curve: Curves.bounceInOut,
                  bottom: height * 0.15,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 0.2,
                              color: const Color.fromARGB(255, 167, 167, 167)),
                          borderRadius: BorderRadius.circular(40),
                          color: Color.fromARGB(44, 0, 0, 0),
                        ),
                        child: Center(
                          child: Icon(
                            isanimate
                                ? CupertinoIcons.volume_up
                                : CupertinoIcons.volume_off,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  duration: Duration(milliseconds: 500),
                ),
              ],
            ),
          ),
          // FadeInUp(
          //     from: 50,
          //     child: Text(
          //       !isanimate ? 'Welcome to RingerRadius' : 'Just Relax',
          //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          //       textAlign: TextAlign.center,
          //     )

          //     ),
          FadeInUp(
              from: 50,
              child: Text(
                !isanimate
                    ? AppLocalizations.of(context)!.onboading_page_welcome
                    : AppLocalizations.of(context)!
                        .onboading_page_welcome_alternative,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                textAlign: TextAlign.center,
              )),
          FadeInUp(
            from: 50,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
              child: Text(
                !isanimate
                    ? AppLocalizations.of(context)!
                        .onboading_page_welcome_description
                    : AppLocalizations.of(context)!
                        .onboading_page_welcome_description_2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Spacer(),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 210, 210, 210),
                  backgroundColor: Colors.black),
              onPressed: () {
                setState(() {
                  isanimate = true;
                  _count++;
                  if (_count == 2) {
                    // Get.off(SignInPage());
                    Get.off(MyHomePage(
                      title: 'Location App',
                    ));

                    // Prints after 1 second.
                  }
                });
              },
              child: isanimate
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 20),
                      child: Text(
                        AppLocalizations.of(context)!
                            .onboading_page_welcome_get_started,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 16),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 20),
                      child: Text(
                        AppLocalizations.of(context)!
                            .onboading_page_welcome_next,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 16),
                      ),
                    )),
          SizedBox(
            height: height * 0.05,
          ),
        ]),
      ),
    );
  }
}
