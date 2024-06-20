import 'package:geolocator/geolocator.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

LocationController controller = Get.put(LocationController());

Future<Position> determinePosition() async {

  return await Geolocator.getCurrentPosition();
}
