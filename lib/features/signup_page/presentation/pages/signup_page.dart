import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.signup_page_app_bar),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signup_page_name,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signup_page_email,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signup_page_phone_number,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signup_page_password,
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  // Perform sign up action here
                  String name = nameController.text;
                  String email = emailController.text;
                  String phone = phoneController.text;
                  String password = passwordController.text;

                  // Validate and process the input data
                  print('Name: $name');
                  print('Email: $email');
                  print('Phone: $phone');
                  print('Password: $password');
                },
                child: Text(AppLocalizations.of(context)!.signup_page_signup_button),
              ),

              SizedBox(height: 20.0),
              Text(AppLocalizations.of(context)!.signup_page_or, textAlign: TextAlign.center,),
              SizedBox(height: 20.0),
              
              ElevatedButton(
                onPressed: () {
                  print('Social media login');
                },
                child: Text(AppLocalizations.of(context)!.signup_page_social_media),
              )
            ],
          ),
        ),
      ),
    );
  }
}
