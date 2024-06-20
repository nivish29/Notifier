import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignInPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.signin_page_app_bar),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signin_page_username,
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.signin_page_password,
                ),
              ),
              
              SizedBox(height: 20.0),

              ElevatedButton(
                onPressed: () {
                  String username = usernameController.text;
                  String password = passwordController.text;

                  print('Username: $username');
                  print('Password: $password');
                },
                child: Text(AppLocalizations.of(context)!.signin_page_submit_button),
              ),

              SizedBox(height: 20.0),
              Text(AppLocalizations.of(context)!.signin_page_or, textAlign: TextAlign.center,),
              SizedBox(height: 20.0),

              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  print('Social media login');
                },
                child: Text(AppLocalizations.of(context)!.signin_page_social_media),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
