import 'package:flutter/material.dart';
import 'package:real_volume/real_volume.dart';
import '../../entry_point/data/sharedPref.dart';

class DndDialog extends StatelessWidget{
  const DndDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme col = Theme.of(context).colorScheme;
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: col.surfaceVariant, // Assuming col is defined somewhere
                borderRadius: BorderRadius.circular(15),
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DND Permission',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'The app requires DND permissions for keeping your phone silent automatically when you need. Calls defined as priority will still come through. Please give DND permissions to the app on the next screen',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Spacer(),
                        FilledButton(
                          onPressed: () async {
                            final dnd =  (await RealVolume.openDoNotDisturbSettings())!;
                            setpref();
                            Navigator.pop(context);
                          },
                          child: Text('Grant'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


}