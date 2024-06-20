import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geomod/entry_point/app.dart';
import 'package:geomod/utils/utils.dart';


void main() async{
  
  //Just for catching errors 
  WidgetsFlutterBinding.ensureInitialized();
  await runZonedGuarded(() async {
    // Loading Production Environment Variables
    try {
      await dotenv.load(fileName: '.env.prod');
      print('Environment variables loaded successfully.');
    } catch (e) {
      print('Failed to load environment variables: $e');
      return;
    }
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully.');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
      return;
    }
    // Loading important utilities before running the app
    try {
      await Utils.initBeforeRunApp();
      print('Utilities initialized successfully.');
    } catch (e) {
      print('Failed to initialize utilities: $e');
      return;
    }

    runApp(App());
  }, (error, stackTrace) {
    print('runZonedGuarded: Caught error in my root zone.');
    print('Error: $error');
    print('StackTrace: $stackTrace');
  });
}