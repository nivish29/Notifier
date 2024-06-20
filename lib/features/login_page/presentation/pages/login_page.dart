import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:geomod/entry_point/controller/app_controller.dart';
import 'package:geomod/features/signin_page/presentation/pages/signin_page.dart';
import 'package:geomod/features/signup_page/presentation/pages/signup_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final appController = Get.find<AppController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.login_page_app_bar),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: 
            (){
              Navigator.push((context), MaterialPageRoute(builder: (context) => SignInPage()));
            }, 
            child: Text(AppLocalizations.of(context)!.login_page_signin_button)
            ),
            ElevatedButton(onPressed: 
            (){
              Navigator.push((context), MaterialPageRoute(builder: (context) => SignUpPage()));
            }, 
            child: Text(AppLocalizations.of(context)!.login_page_signup_button)
            ),
            ElevatedButton(onPressed: (){
              if(appController.locale.languageCode == 'en'){
                appController.changeLanguage(const Locale('hi'));
              }else{
                appController.changeLanguage(const Locale('en'));
              }
            }, 
            child: Text(AppLocalizations.of(context)!.login_page_change_language)
            ),
          ],
        ),
      ),
    );
  }
}
