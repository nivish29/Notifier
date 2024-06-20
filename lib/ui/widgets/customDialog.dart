import 'package:flutter/material.dart';
import 'package:geomod/entry_point/controller/app_controller.dart';
import 'package:get/get.dart';

class CustomDialog extends StatefulWidget {
  final String text;

  CustomDialog({required this.text});

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  String selectedLanguage = 'Select Language'; // Default language text
  AppController appController = Get.put(AppController());

  @override
  Widget build(BuildContext context) {
    final ColorScheme col = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final Color dropdownColor = theme.dialogBackgroundColor.withOpacity(0.3);
    final Color dialogColor = theme.dialogBackgroundColor;
    final width = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: AlertDialog(
        backgroundColor: dialogColor,
        content: SizedBox(
          width: width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text(widget.text, style: TextStyle(color: col.surfaceTint)),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildLanguageDialog(),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: dropdownColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedLanguage,
                        style: TextStyle(color:col.onSurface),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: col.surfaceTint),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back(result: false);
            },
            child: Text(
              selectedLanguage == 'हिंदी' ? 'नहीं' : 'No',
              style: TextStyle(color: col.surfaceTint),
            ),
          ),
          TextButton(
            onPressed: () {
              if (selectedLanguage != 'Select Language') {
                if (selectedLanguage == 'हिंदी') {
                  appController.changeLanguage(const Locale('hi'));
                } else {
                  appController.changeLanguage(const Locale('en'));
                }
              }
              Get.back(result: true);
            },
            child: Text(
              selectedLanguage == 'हिंदी' ? 'हाँ' : 'Yes',
              style: TextStyle(color: col.surfaceTint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDialog() {
    return AlertDialog(
      title: Text('Select Language',),
      content: Container(
        width: double.maxFinite,
        height: 200,
        child: ListView(
          children: [
            _buildLanguageItem('English', 'en'),
            _buildLanguageItem('हिंदी', 'hi'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String label, String languageCode) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          selectedLanguage = label; // Update the selected language
        });
        // Get.updateLocale(Locale(languageCode));
        Get.back();
      },
    );
  }
}
