import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:geomod/entry_point/controller/location_controller.dart';
import 'package:geomod/entry_point/model/model.dart';
import 'package:geomod/features/logic/background_logic.dart';
import 'package:geomod/features/logic/list_access.dart';
import 'package:get/get.dart';
// import 'package:location_app/controller/location_controller.dart';
// import 'package:location_app/logic/background_logic.dart';
// import 'package:location_app/logic/list_access.dart';
// import 'package:location_app/model/model.dart';
import 'package:network_info_plus/network_info_plus.dart';

class wifi_ssid extends StatefulWidget {
  @override
  _wifi_ssidState createState() => _wifi_ssidState();
}

class _wifi_ssidState extends State<wifi_ssid> {
  String _wifiSSID = 'Unknown';

  @override
  void initState() {
    super.initState();
    _getWifiName();
  }

  Future<void> _getWifiName() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) {
      String? wifiSSID = await NetworkInfo().getWifiName();
      print('wifi ssid:');
      print(wifiSSID);

      setState(() {
        _wifiSSID = wifiSSID ?? 'Unknown';
      });
    } else {
      setState(() {
        _wifiSSID = 'Not connected to Wi-Fi';
      });
    }
    alreadywifi(_wifiSSID);
  }

  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final LocationController controller = Get.find();
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 240, 240, 240),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 240, 240, 240),
        title: Text('Connected Wi-Fi SSID'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 249, 246, 249),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter custom wifi name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                ),
              ),
            ),
            Text('Connected Wi-Fi SSID: $_wifiSSID'),
            TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 33, 54, 243),
                    foregroundColor: Colors.white),
                onPressed: () async {
                  if ( _wifiSSID == 'Not connected to Wi-Fi'){
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Check'),
                          content: Text('Device is Not Connected to Wi-Fi'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                  else{
                    if (await alreadywifi(_wifiSSID) == true) {
                      print('adding data');
                      controller.dataToShow.value.add(
                        Data(
                          isFav: true,
                          name: _controller.text,
                          latitude: 0.00,
                          longitude: 0.00,
                          radius: 0.0,
                          music: 0.0,
                          alarm: 0.0,
                          notiication: 0.0,
                          ring: 0.0,
                          ringerMode: 0.0,
                          timeHour: -1,
                          timeMinute: -1,
                          timeHour_end: -1,
                          timeMinute_end: -1,
                        ),
                      );
                      Navigator.of(context).pop();
                      controller.update();
                      storingData(controller.dataToShow.value);
                    } else {
                      print('not adding data');
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Check'),
                            content: Text('This wifi is already added'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
                child: Text('Add current wifi'))
          ],
        ),
      ),
    );
  }
}
