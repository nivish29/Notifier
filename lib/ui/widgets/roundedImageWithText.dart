import 'package:flutter/material.dart';

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
