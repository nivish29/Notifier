import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocationController controller = Get.put(LocationController());
void getpref() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? repeat = prefs.getBool('onboarding');
  controller.onboarding.value = repeat??false;
}

void setpref() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding', true);
  controller.onboarding.value = true;
  print("onboard off");
}
