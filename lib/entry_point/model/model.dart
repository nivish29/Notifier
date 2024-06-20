import 'dart:convert';

class Data {
  final double latitude, longitude, ringerMode;
  final double radius, ring, music, alarm, notiication;
  final int timeHour, timeMinute;
  final int timeHour_end, timeMinute_end;
  final String name;
  bool isFav;

  Data({
    required this.isFav,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.ring,
    required this.music,
    required this.alarm,
    required this.notiication,
    required this.ringerMode,
    required this.timeHour,
    required this.timeMinute,
    required this.timeHour_end,
    required this.timeMinute_end,
  });

  factory Data.fromJson(Map<String, dynamic> jsonData) {
    return Data(
      isFav: jsonData['isFav'] ?? false,
      name: jsonData['name'],
      latitude: jsonData['latitude'],
      longitude: jsonData['longitude'],
      music: jsonData['music'],
      ring: jsonData['ring'],
      alarm: jsonData['alarm'],
      radius: jsonData['radius'],
      notiication: jsonData['notiication'],
      ringerMode: jsonData['ringerMode'],
      timeHour: jsonData['timeHour'],
      timeMinute: jsonData['timeMinute'],
      timeHour_end: jsonData['timeHour_end'],
      timeMinute_end: jsonData['timeMinute_end'],
    );
  }

  static Map<String, dynamic> toMap(Data data) => {
        'isFav': data.isFav,
        'name': data.name,
        'latitude': data.latitude,
        'longitude': data.longitude,
        'music': data.music,
        'ring': data.ring,
        'alarm': data.alarm,
        'radius':data.radius,
        'notiication': data.notiication,
        'ringerMode': data.ringerMode,
        'timeHour': data.timeHour,
        'timeMinute': data.timeMinute,
        'timeHour_end': data.timeHour_end,
        'timeMinute_end': data.timeMinute_end,
      };

  static String encode(List<Data> datas) => json.encode(
        datas.map<Map<String, dynamic>>((data) => Data.toMap(data)).toList(),
      );

  static List<Data> decode(String datas) =>
      (json.decode(datas) as List<dynamic>)
          .map<Data>((item) => Data.fromJson(item))
          .toList();
}
