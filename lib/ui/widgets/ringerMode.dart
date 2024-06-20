import 'package:flutter/material.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:real_volume/real_volume.dart';

class Ringermode extends StatefulWidget {
  LocationController controller = Get.put(LocationController());
  @override
  _RingermodeState createState() => _RingermodeState();
}

class _RingermodeState extends State<Ringermode> {
  LocationController controller = Get.put(LocationController());
  double volumevalue = 0.0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme col = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        selectedIcon: Icon(Icons.done_rounded),
        segments: <ButtonSegment<int>>[
          ButtonSegment<int>(
              value: 0,
              label: Text(AppLocalizations.of(context)!
                  .location_access_ringer_mode_normal),
              icon: Icon(Icons.notifications_active_outlined)),
          ButtonSegment<int>(
              value: 1,
              label: Text(AppLocalizations.of(context)!
                  .location_access_ringer_mode_vibrate),
              icon: Icon(Icons.vibration_outlined)),
          ButtonSegment<int>(
              value: 2,
              label: Text(AppLocalizations.of(context)!
                  .location_access_ringer_mode_silent),
              icon: Icon(Icons.notifications_off_outlined)),
        ],
        selected: <int>{controller.ringermode.value.toInt()},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            if (newSelection.contains(2)) {
              // If "Silent" segment is selected
              if (!controller.isdnd.value) {
                // If DND is not enabled, deselect "Silent"
                newSelection.remove(2);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please grant DND permissions'),
                    action: SnackBarAction(
                      label: 'Grant',
                      onPressed: () {
                        RealVolume.openDoNotDisturbSettings();
                      },
                    ),
                  ),
                );
              }
            }
            print(
                "controller.ringermode.value : ${controller.ringermode.value}");
            controller.ringermode.value = newSelection.first.toDouble();
          });
        },
      ),
    );
  }
}
