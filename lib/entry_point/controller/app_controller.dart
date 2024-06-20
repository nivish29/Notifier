import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppController extends GetxController {
  Locale? _locale = const Locale('en');
  Locale get locale => _locale!;

  AppController() {
    print('AppController init');
  }

  Future<String> getLocale()async{
     SharedPreferences pref = await SharedPreferences.getInstance();
     return pref.getString('language_code')??'';
  }

  void changeLanguage(Locale locale) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _locale = locale;

    if (locale == Locale('en')) {
      pref.setString('language_code', 'en');
    } else {
      pref.setString('language_code', 'hi');
    }
    Get.updateLocale(locale);
    print('Language changed to ${locale.languageCode}');
    update();
  }
}
