import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:geomod/features/logic/list_access.dart';
import 'package:geomod/services/analyticService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class ArchivesPage extends StatefulWidget {
  const ArchivesPage({super.key});

  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  @override
  Widget build(BuildContext context) {
    // Analytic event
    logEventMain('navigation_archive');
    LocationController controller = Get.put(LocationController());
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final ColorScheme col = Theme.of(context).colorScheme;
    Map<String, IconData> mp = {
      'Add Manually': Icons.location_on,
      'Home': Icons.home_filled,
      'College/School': Icons.school,
      'Work': Icons.work,
      'Temple': Icons.temple_hindu_rounded,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home_page_archive),
        actions: [
          controller.dataToShow_arc.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilledButton.tonalIcon(
                      onPressed: () {
                        controller.dataToShow_arc.value = [];
                        storingData_arc(controller.dataToShow_arc.value);
                        setState(() {});
                      },
                      icon: Icon(Icons.clear_all_rounded),
                      label: Text(
                          AppLocalizations.of(context)!.archive_clear_all)),
                )
              : const SizedBox()
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: controller.dataToShow_arc.value.length > 0
            ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 3,
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 4.0, // Spacing between columns
                  mainAxisSpacing: 4.0, // Spacing between rows
                ),
                itemCount: controller
                    .dataToShow_arc.value.length, // Number of items in the grid
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      showCupertinoModalPopup<void>(
                        barrierColor: Colors.black.withOpacity(0.5),
                        context: context,
                        builder: (BuildContext context) => CupertinoActionSheet(
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              AppLocalizations.of(context)!.archive_remove,
                              style: TextStyle(
                                  fontSize: 16, color: col.onBackground),
                            ),
                          ),
                          // message: const Text('Would you like to unarchive/delete'),
                          actions: <CupertinoActionSheetAction>[
                            CupertinoActionSheetAction(
                              /// This parameter indicates the action would be a default
                              /// default behavior, turns the action's text to bold text.
                              isDefaultAction: true,
                              onPressed: () {
                                controller.dataToShow.value.add(
                                  Data(
                                    isFav: controller
                                        .dataToShow_arc.value[index].isFav,
                                    name: controller
                                        .dataToShow_arc.value[index].name,
                                    // name: controller.locationName,
                                    latitude: controller
                                        .dataToShow_arc.value[index].latitude,
                                    longitude: controller
                                        .dataToShow_arc.value[index].longitude,
                                    radius: controller
                                        .dataToShow_arc.value[index].radius,
                                    music: controller
                                        .dataToShow_arc.value[index].music,
                                    alarm: controller
                                        .dataToShow_arc.value[index].alarm,
                                    notiication: controller
                                        .dataToShow_arc.value[index].notiication,
                                    ring:
                                        controller.dataToShow.value[index].ring,
                                    ringerMode: controller
                                        .dataToShow_arc.value[index].ringerMode,
                                    timeHour: controller
                                        .dataToShow_arc.value[index].timeHour,
                                    timeMinute: controller
                                        .dataToShow_arc.value[index].timeMinute,
                                    timeHour_end: controller.dataToShow_arc
                                        .value[index].timeHour_end,
                                    timeMinute_end: controller.dataToShow_arc
                                        .value[index].timeMinute_end,
                                  ),
                                );

                                controller.update();
                                storingData(controller.dataToShow.value);

                                controller.dataToShow_arc.value.removeAt(index);
                                storingData_arc(
                                    controller.dataToShow_arc.value);
                                setState(() {});

                                // Analytic event
                                logEventMain('navigation_unarchived');
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!
                                  .archive_page_unarchive),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!
                                  .archive_page_cancel),
                            ),
                            CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                controller.dataToShow_arc.value.removeAt(index);
                                storingData_arc(
                                    controller.dataToShow_arc.value);
                                setState(() {});
                                Navigator.pop(context);
                                // Analytic event
                                logEventMain('navigation_deleted');
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.archive_remove),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      height: 100,
                      width: width * 0.5,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 15,
                          ),
                          Icon(
                            mp[controller.dataToShow_arc.value[index].name] ??
                                Icons.location_city_rounded,
                            color: col.onPrimaryContainer,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: width * 0.3,
                            child: Text(
                              '${controller.dataToShow_arc.value[index].name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        color: col.primaryContainer,
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: SizedBox(
                  height: height * 0.2,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.compare_arrows_outlined,
                          size: 30,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            AppLocalizations.of(context)!.archive_page_swipe,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
