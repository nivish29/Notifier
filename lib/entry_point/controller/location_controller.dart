import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/model.dart';

class mapview {
  MapType mp;

  mapview({
    required this.mp,
  });
}

class LocationController extends GetxController {
  var dataToShow = <Data>[].obs;
  var dataToShow_fav = <Data>[].obs;
  var dataToShow_arc = <Data>[].obs;
  var maptype = mapview(mp: MapType.normal).obs;

  var ln = "".obs;
  late LatLng selectedLocation;
  RxString locationName = "".obs;
  RxString locationaddress = "".obs;
  RxDouble axis = 0.0.obs;
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  var onboarding = false.obs;
  RxDouble radius = 50.0.obs;
  var showDialog=false.obs;
  var drivng = false.obs;
  RxBool isfavouriteloading = true.obs;
  RxInt isfavourite = 0.obs;
  RxDouble ringermode = 0.0.obs;
  RxDouble ring = 0.0.obs;
  RxDouble voicecall = 100.0.obs;
  RxDouble system = 60.0.obs;
  RxDouble music = 0.0.obs;
  RxDouble alarm = 0.0.obs;
  RxDouble notfication = 0.0.obs;
var toshow=false.obs;
  RxBool fetchingLoader = false.obs;
  RxBool isdnd = false.obs;
  RxBool isexpandedmap = false.obs;

  void clear() {
    ln.value = '';
    ringermode.value = 0.0;
    ring.value = 0.0;
    voicecall.value = 0.0;
    system.value = 0.0;
    music.value = 0.0;
    alarm.value = 0.0;
    notfication.value = 0.0;
    radius.value = 50.0;
  }

  List<Data> getUpdatedDataToShow() {
    return dataToShow;
  }

  Future<void> updateLocationName() async {
    print("Start");
    print('current location name: ${selectedLocation.latitude}, ${selectedLocation.longitude}');
    List<Placemark> placeMarks = await placemarkFromCoordinates(
      selectedLocation.latitude,
      selectedLocation.longitude,
    );
    if (placeMarks.isNotEmpty) {
      String locName = placeMarks[0].name ?? "Name not found";
      print("Loc Name : $locName");
      String address =
          "${placeMarks[0].street ?? ""} ${placeMarks[0].locality ?? ""} ${placeMarks[0].postalCode ?? ""} ${placeMarks[0].country ?? ""}";

      locationaddress.value = address;
      locationName.value = locName;
      print(locationName);
      update();
    }
    print("ended");
  }

  Future<Uint8List> createAssetImageToUint8List() async {
    // Load the image asset
    final ByteData byteData = await rootBundle.load('lib/assets/home.jpg');
    final Uint8List uint8List = byteData.buffer.asUint8List();

    // Compress the image
    final result = await FlutterImageCompress.compressWithList(
      uint8List,
      minWidth: 100,
      minHeight: 100,
      quality: 100,
    );

    return result;
  }

  List<String> busSvgList() {
    // Add your SVG codes here
    return [
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 99 123.75" enable-background="new 0 0 99 99" xml:space="preserve"><path fill-rule="evenodd" clip-rule="evenodd" d="M44.828,33.738c-0.726-0.711-1.897-0.707-2.613,0.009l-0.129,0.129  c-0.717,0.716-0.71,1.874,0.019,2.587l3.962,3.861l0.077,0.075l0.054,0.053c0.721,0.703,1.866,0.681,2.562-0.047l9.316-9.589  c0.713-0.743,0.71-1.93-0.003-2.655l-0.131-0.13c-0.717-0.728-1.878-0.711-2.592,0.037l-7.928,8.2L44.828,33.738z M23.751,35.716  c0.183,11.854,26.373,53.941,26.373,53.941s26.189-43.006,26.373-53.941C76.741,21.153,64.689,9.343,50.124,9.343  C35.56,9.343,23.525,21.153,23.751,35.716z M33.491,34.337c0-9.033,7.325-16.356,16.357-16.356c9.033,0,16.356,7.323,16.356,16.356  c0,9.034-7.323,16.358-16.356,16.358C40.816,50.695,33.491,43.371,33.491,34.337z"/><text x="0" y="114" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Hakan Yalcin</text><text x="0" y="119" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif"></text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 100 125" style="enable-background:new 0 0 100 100;" xml:space="preserve"><g><path d="M57.1,33.3v-3.9c0-0.1-0.1-0.1-0.1-0.2c0.2,0,0.4-0.2,0.4-0.4c0-0.3-0.2-0.4-0.5-0.4h-2c-0.3,0-0.5,0.2-0.5,0.4   c0,0.2,0.1,0.4,0.4,0.4c0,0.1-0.1,0.1-0.1,0.2v1.7l-3.9-4c0,0,0,0,0-0.1c-0.2-0.2-0.5-0.3-0.8-0.3c-0.3,0-0.6,0.1-0.8,0.3   c0,0,0,0-0.1,0.1L37.6,38.6c-0.4,0.4-0.4,1.1,0,1.6c0.4,0.4,1.1,0.4,1.6,0L50,29.4l10.8,10.8c0.4,0.4,1.1,0.4,1.6,0   c0.4-0.4,0.5-1.1,0.1-1.6L57.1,33.3z"/><path d="M40.8,39.8v11.4c0,0.4,0.3,0.8,0.9,0.8h4.8c0.4,0,0.7-0.4,0.7-0.8v-7.7c0-0.4,0.4-0.8,0.8-0.8H52c0.4,0,0.8,0.4,0.8,0.8   v7.7c0,0.4,0.2,0.8,0.7,0.8h4.8c0.5,0,0.9-0.3,0.9-0.8V39.8L50,30.5L40.8,39.8z"/><path d="M50,10c-16.5,0-29.8,13.3-29.8,29.8S50,90,50,90s29.8-33.7,29.8-50.2S66.5,10,50,10z M50,60.8c-11.5,0-20.9-9.3-20.9-20.9   S38.5,19.1,50,19.1S70.9,28.4,70.9,40S61.5,60.8,50,60.8z"/></g><text x="0" y="115" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Musmellow</text><text x="0" y="120" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 512 640" style="enable-background:new 0 0 512 512;" xml:space="preserve"><g><g><g><path d="M255.996,0c-47.372,0-93.252,20.134-129.188,56.692c-34.023,34.615-53.647,78.525-53.827,120.47     c-0.179,41.271,32.988,114.046,95.913,210.454C204.625,442.36,240.76,490.47,257.308,512     c16.387-21.654,52.166-70.018,87.48-124.908c62.18-96.648,94.762-169.207,94.225-209.826C437.905,93.589,359.4,0,255.996,0z      M255.996,323.479c-81.188,0-147.242-66.056-147.242-147.245c0-81.191,66.054-147.246,147.242-147.246     c81.194,0,147.245,66.624,147.245,147.246C403.241,257.423,337.188,323.479,255.996,323.479z"/></g><g><rect x="204.051" y="250.017" width="38.009" height="9.5"/><rect x="246.81" y="159.745" width="19.005" height="99.773"/><rect x="204.051" y="159.745" width="38.009" height="85.521"/><rect x="180.294" y="159.745" width="19.005" height="99.773"/><polygon points="310.951,264.27 268.188,264.27 244.436,264.27 201.675,264.27 177.92,264.27 166.041,264.27 166.041,278.523      346.583,278.523 346.583,264.27 334.704,264.27    "/><rect x="270.566" y="250.017" width="38.007" height="9.5"/><path d="M201.675,154.996h42.761h23.753h42.763h23.753h18.035l-96.427-46.119V95.607h23.755V81.354h-23.755v-4.752h-4.751v32.236     c-18.662,8.743-34.137,16.751-49.121,24.506c-14.084,7.288-27.519,14.241-43.179,21.651h18.658H201.675z M255.864,121.738     c6.551,0,11.879,5.328,11.879,11.876c0,6.549-5.328,11.877-11.879,11.877c-6.547,0-11.875-5.328-11.875-11.877     C243.989,127.066,249.317,121.738,255.864,121.738z"/><rect x="313.325" y="159.745" width="19.005" height="99.773"/><rect x="270.566" y="159.745" width="38.007" height="85.521"/><path d="M255.864,140.741c3.932,0,7.128-3.196,7.128-7.126c0-3.93-3.196-7.126-7.128-7.126c-3.928,0-7.126,3.196-7.126,7.126     C248.738,137.545,251.937,140.741,255.864,140.741z"/></g></g></g><text x="0" y="527" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Flatart</text><text x="0" y="532" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 512 640" style="enable-background:new 0 0 512 512;" xml:space="preserve"><g><g><g><path d="M255.996,0c-47.372,0-93.252,20.134-129.188,56.692c-34.023,34.615-53.647,78.525-53.827,120.47     c-0.179,41.271,32.988,114.046,95.913,210.454C204.625,442.36,240.76,490.47,257.308,512     c16.387-21.654,52.166-70.018,87.48-124.908c62.18-96.648,94.762-169.207,94.225-209.826C437.905,93.589,359.4,0,255.996,0z      M255.996,323.479c-81.188,0-147.242-66.056-147.242-147.245c0-81.191,66.054-147.246,147.242-147.246     c81.194,0,147.245,66.624,147.245,147.246C403.241,257.423,337.188,323.479,255.996,323.479z"/></g><g><rect x="204.051" y="250.017" width="38.009" height="9.5"/><rect x="246.81" y="159.745" width="19.005" height="99.773"/><rect x="204.051" y="159.745" width="38.009" height="85.521"/><rect x="180.294" y="159.745" width="19.005" height="99.773"/><polygon points="310.951,264.27 268.188,264.27 244.436,264.27 201.675,264.27 177.92,264.27 166.041,264.27 166.041,278.523      346.583,278.523 346.583,264.27 334.704,264.27    "/><rect x="270.566" y="250.017" width="38.007" height="9.5"/><path d="M201.675,154.996h42.761h23.753h42.763h23.753h18.035l-96.427-46.119V95.607h23.755V81.354h-23.755v-4.752h-4.751v32.236     c-18.662,8.743-34.137,16.751-49.121,24.506c-14.084,7.288-27.519,14.241-43.179,21.651h18.658H201.675z M255.864,121.738     c6.551,0,11.879,5.328,11.879,11.876c0,6.549-5.328,11.877-11.879,11.877c-6.547,0-11.875-5.328-11.875-11.877     C243.989,127.066,249.317,121.738,255.864,121.738z"/><rect x="313.325" y="159.745" width="19.005" height="99.773"/><rect x="270.566" y="159.745" width="38.007" height="85.521"/><path d="M255.864,140.741c3.932,0,7.128-3.196,7.128-7.126c0-3.93-3.196-7.126-7.128-7.126c-3.928,0-7.126,3.196-7.126,7.126     C248.738,137.545,251.937,140.741,255.864,140.741z"/></g></g></g><text x="0" y="527" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Flatart</text><text x="0" y="532" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 100 125" enable-background="new 0 0 100 100" xml:space="preserve"><g><path fill="#000000" d="M600,568.286c-13.807,0-25,11.193-25,25c0,13.808,25,38.428,25,38.428s25-24.62,25-38.428   C625,579.479,613.807,568.286,600,568.286z M600,612.803c-10.925,0-19.782-8.856-19.782-19.781   c0-10.926,8.857-19.782,19.782-19.782s19.782,8.856,19.782,19.782C619.782,603.946,610.925,612.803,600,612.803z"/><path fill="#000000" d="M610.347,590.324h-0.574l-1.305-4.859c-0.136-0.619-0.654-1.054-1.462-1.054h-14.297   c-0.809,0-1.368,0.449-1.463,1.054l-1.125,4.859h-0.468c-1.055,0-1.91,0.712-1.91,1.59v5.011c0,0.787,0.688,1.439,1.591,1.566   v1.341c0,0.878,0.711,1.59,1.59,1.59h2.385c0.878,0,1.59-0.712,1.59-1.59v-1.316h10.203v1.316c0,0.878,0.712,1.59,1.59,1.59h2.385   c0.878,0,1.59-0.712,1.59-1.59v-1.341c0.902-0.127,1.591-0.779,1.591-1.566v-5.011   C612.257,591.036,611.401,590.324,610.347,590.324z M592.476,586.575c0.082-0.501,0.563-0.92,1.259-0.92h12.307   c0.695,0,1.182,0.419,1.259,0.92l0.991,3.749h-16.67L592.476,586.575z M592.646,596.928c-1.434,0-2.596-1.162-2.596-2.595   c0-1.434,1.162-2.596,2.596-2.596c1.433,0,2.595,1.162,2.595,2.596C595.241,595.766,594.079,596.928,592.646,596.928z    M607.354,596.928c-1.433,0-2.595-1.162-2.595-2.595c0-1.434,1.162-2.596,2.595-2.596c1.434,0,2.596,1.162,2.596,2.596   C609.949,595.766,608.787,596.928,607.354,596.928z"/></g><g><path fill="#000000" d="M50,18.286c-13.807,0-25,11.193-25,25c0,13.808,25,38.428,25,38.428s25-24.62,25-38.428   C75,29.479,63.807,18.286,50,18.286z M50,62.803c-10.925,0-19.782-8.856-19.782-19.782c0-10.925,8.857-19.782,19.782-19.782   s19.782,8.857,19.782,19.782C69.782,53.946,60.925,62.803,50,62.803z"/><path fill="#000000" d="M39.554,37.745V50.36c0,0.844,0.684,1.527,1.527,1.527h1.646V36.218h-1.646   C40.237,36.218,39.554,36.902,39.554,37.745z"/><path fill="#000000" d="M58.919,36.218h-1.646v15.669h1.646c0.844,0,1.527-0.684,1.527-1.527V37.745   C60.446,36.902,59.763,36.218,58.919,36.218z"/><path fill="#000000" d="M53.665,35.406c0-0.607-0.403-1.1-0.9-1.1h-5.529c-0.497,0-0.9,0.492-0.9,1.1v0.813h-2.899v15.669h13.129   V36.218h-2.899V35.406z M47.769,35.314h4.463c0.357,0,0.654,0.39,0.715,0.904h-5.893C47.114,35.704,47.411,35.314,47.769,35.314z    M54.132,48.796l1.267,0.184l-0.916,0.894l0.216,1.262l-1.133-0.596l-1.133,0.596l0.216-1.262l-0.916-0.894l1.267-0.184   l0.566-1.148L54.132,48.796z"/></g><text x="0" y="115" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by asianson.design</text><text x="0" y="120" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 100 125" enable-background="new 0 0 100 100" xml:space="preserve"><path d="M50,2.248c-20.046,0-36.354,16.309-36.355,36.355c0,4.068,0.667,8.062,1.982,11.873  c6.04,17.401,16.431,33.138,30.017,45.479c1.166,1.159,2.712,1.797,4.356,1.797c1.645,0,3.189-0.638,4.322-1.766  c13.617-12.37,24.009-28.108,30.051-45.513c1.314-3.81,1.982-7.805,1.982-11.871C86.355,18.557,70.047,2.248,50,2.248z M50,66.109  c-15.241,0-27.64-12.397-27.64-27.637c0-15.24,12.399-27.639,27.64-27.639c15.24,0,27.639,12.397,27.639,27.638  C77.639,53.712,65.24,66.109,50,66.109z"/><path d="M67.909,45.202L57.736,35.028v-2.251l0.01,0.017c0.276,0.479,0.889,0.641,1.366,0.366c0.479-0.276,0.643-0.888,0.366-1.366  l-8.613-14.917c-0.357-0.619-1.375-0.619-1.732,0l-8.612,14.917c-0.276,0.479-0.112,1.09,0.366,1.366  c0.347,0.2,1.022,0.229,1.366-0.366l0.01-0.017v2.251c0,0-8.08,8.08-8.081,8.08l-2.093,2.093c-0.391,0.391-0.391,1.023,0,1.414  s1.023,0.391,1.414,0l0.387-0.387v7.929c0,0.553,0.448,1,1,1h30.219c0.553,0,1-0.447,1-1v-7.929l0.387,0.387  c0.424,0.424,1.059,0.356,1.414,0C68.3,46.225,68.3,45.592,67.909,45.202z M35.89,44.229l6.373-6.373v15.302H35.89V44.229z   M44.263,29.313l5.736-9.936l5.737,9.937v23.845h-1.897v-6.747c0-2.117-1.723-3.839-3.84-3.839c-2.117,0-3.839,1.722-3.839,3.839  v6.747h-1.897V29.313z M51.839,53.158H48.16v-6.747c0-1.014,0.825-1.839,1.839-1.839c1.015,0,1.84,0.825,1.84,1.839V53.158z   M64.108,53.158h-6.372V37.856l6.372,6.373V53.158z"/><text x="0" y="115" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by habione 404</text><text x="0" y="120" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>''',
      '''<svg xmlns="http://www.w3.org/2000/svg" data-name="Gym Pin" viewBox="0 0 37.87 65" x="0px" y="0px"><title>gym-pin</title><path d="M192,6a18.94,18.94,0,0,0-18.94,18.94c0,9.14,14.47,28,18.11,32.63a1,1,0,0,0,1.65,0c3.64-4.61,18.11-23.49,18.11-32.63A18.94,18.94,0,0,0,192,6Zm1.64,31.46a12.63,12.63,0,0,1-14.16-14.16c0.65-5.19,5.69-10.22,10.88-10.88a12.63,12.63,0,0,1,14.16,14.16C203.87,31.77,198.83,36.8,193.64,37.46Zm4.28-19.94,1.88,2a1,1,0,0,1,0,1.41l-1,.94,0.71,0.75a1.18,1.18,0,0,1-1.71,1.63l-1.52-1.6-6.85,6.51,1.52,1.6a1.18,1.18,0,0,1-1.71,1.63l-0.71-.75-1,.94a1,1,0,0,1-1.41,0l-1.88-2a1,1,0,0,1,0-1.41l1-.94-0.92-1A1.18,1.18,0,0,1,186,25.6l1.73,1.82,6.85-6.51-1.73-1.82a1.18,1.18,0,0,1,1.71-1.63l0.92,1,1-.94A1,1,0,0,1,197.92,17.52Z" transform="translate(-173.06 -6)"/><text x="0" y="67" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Isma Ruiz</text><text x="0" y="72" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">from the Noun Project</text></svg>'''
    ];
  }

  Future<List<BitmapDescriptor>> getSvgIconList() async {
    List<String> svgList = busSvgList();
    List<BitmapDescriptor> iconList = [];
    print('bus svg list:${svgList.length}');
    for (String svgString in svgList) {
      final PictureInfo pictureInfo =
          await vg.loadPicture(SvgStringLoader(svgString), null);

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      canvas.drawPicture(pictureInfo.picture);
      final ui.Image image =
          await pictureRecorder.endRecording().toImage(100, 100);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8list = byteData!.buffer.asUint8List();

      iconList.add(BitmapDescriptor.fromBytes(uint8list));
    }

    return iconList;
  }

  String busSvg() {
    return '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="0px" y="0px" viewBox="0 0 99 123.75" enable-background="new 0 0 99 99" xml:space="preserve"><path fill-rule="evenodd" clip-rule="evenodd" d="M44.828,33.738c-0.726-0.711-1.897-0.707-2.613,0.009l-0.129,0.129  c-0.717,0.716-0.71,1.874,0.019,2.587l3.962,3.861l0.077,0.075l0.054,0.053c0.721,0.703,1.866,0.681,2.562-0.047l9.316-9.589  c0.713-0.743,0.71-1.93-0.003-2.655l-0.131-0.13c-0.717-0.728-1.878-0.711-2.592,0.037l-7.928,8.2L44.828,33.738z M23.751,35.716  c0.183,11.854,26.373,53.941,26.373,53.941s26.189-43.006,26.373-53.941C76.741,21.153,64.689,9.343,50.124,9.343  C35.56,9.343,23.525,21.153,23.751,35.716z M33.491,34.337c0-9.033,7.325-16.356,16.357-16.356c9.033,0,16.356,7.323,16.356,16.356  c0,9.034-7.323,16.358-16.356,16.358C40.816,50.695,33.491,43.371,33.491,34.337z"/><text x="0" y="114" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif">Created by Hakan Yalcin</text><text x="0" y="119" fill="#000000" font-size="5px" font-weight="bold" font-family="'Helvetica Neue', Helvetica, Arial-Unicode, Arial, Sans-serif"></text></svg>''';
  }

  Future<BitmapDescriptor> getSvgIcon() async {
    String svgString = busSvg();

    final PictureInfo pictureInfo =
        await vg.loadPicture(SvgStringLoader(svgString), null);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.drawPicture(pictureInfo.picture);
    final ui.Image image =
        await pictureRecorder.endRecording().toImage(100, 100);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8list = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8list);
  }
}
