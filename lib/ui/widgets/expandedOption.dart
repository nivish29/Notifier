
import 'package:flutter/material.dart';

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