import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
LocationController controller = Get.put(LocationController());
gettingData() async {
  List<Data> empty = [];
  final SharedPreferences prefs = await _prefs;
  prefs.reload();
  final String? musicsString = prefs.getString("Data");
  if (musicsString != null) {
    var dataToShow = Data.decode(musicsString);
    print(dataToShow);
    return dataToShow;
  }
  return empty;
}

storingData(dataToStore) async {
  final SharedPreferences prefs = await _prefs;
  final String encodedData = Data.encode(dataToStore);
  print(dataToStore);
  print("Data stored");
  prefs.remove("Data");
  prefs.setString("Data", encodedData);
}

gettingData_fav() async {
  List<Data> empty = [];
  final SharedPreferences prefs = await _prefs;
  prefs.reload();
  final String? musicsString = prefs.getString("Data1");
  if (musicsString != null) {
    var dataToShow = Data.decode(musicsString);
    print(dataToShow);
    return dataToShow;
  }
  return empty;
}

storingData_fav(dataToStore) async {
  final SharedPreferences prefs = await _prefs;
  final String encodedData = Data.encode(dataToStore);
  print(dataToStore);
  prefs.remove("Data1");
  prefs.setString("Data1", encodedData);
}

gettingData_arc() async {
  List<Data> empty = [];
  final SharedPreferences prefs = await _prefs;
  prefs.reload();
  final String? musicsString = prefs.getString("Data2");
  if (musicsString != null) {
    var dataToShow = Data.decode(musicsString);
    print(dataToShow);
    return dataToShow;
  }
  return empty;
}

storingData_arc(dataToStore) async {
  final SharedPreferences prefs = await _prefs;
  final String encodedData = Data.encode(dataToStore);
  print(dataToStore);
  prefs.remove("Data2");
  prefs.setString("Data2", encodedData);
}

// Future<bool> isfavourite() async {
//   List<Data> dataToShow = await gettingData();

//   for (var element in dataToShow) {
//     if (element.ssid == 'true') {
//       controller.isfavouriteloading.value = false;
      
//       return true;
//     }
//   }
// controller.isfavouriteloading.value = false;

//   return false;
// }
