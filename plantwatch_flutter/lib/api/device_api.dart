import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:plantwatch_flutter/models/reading.dart';

import '../models/device.dart';

var baseUrl = dotenv.env['PLANTWATCH_API_HOST']!;

class DeviceApi {
  static Future<List<dynamic>> getDevices() async {
    try {
      var requestUrl = Uri.http(baseUrl, "/devices");
      var response = await http.get(requestUrl);
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<dynamic>>?);
    }
  }

  static Future<List<dynamic>> getUserDevices() async {
    try {
      var token = await FirebaseAuth.instance.currentUser!.getIdToken();

      var requestUrl = Uri.http(baseUrl, "/devices");
      var response = await http
          .get(requestUrl, headers: {"Authorization": "Bearer ${token}"});
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<dynamic>>?);
    }
  }

  static addDeviceToAccount(String deviceId) async {
    try {
      var token = await FirebaseAuth.instance.currentUser!.getIdToken();
      var requestUrl = Uri.http(baseUrl, "/devices/$deviceId/user");
      var response = await http
          .put(requestUrl, headers: {"Authorization": "Bearer ${token}"});
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<dynamic>>?);
    }
  }

  static Future<List<dynamic>> getDeviceReadings(String deviceId) async {
    try {
      var requestUrl = Uri.http(baseUrl, "/devices/$deviceId/readings");
      var response = await http.get(requestUrl);
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<dynamic>>?);
    }
  }

  static setDeviceParameters(Device device, double minTemp, double maxTemp,
      double minHum, double maxHum, double minMoist, double maxMoist) async {
    try {
      var parameters = {
        "minTemp": minTemp,
        "maxTemp": maxTemp,
        "minHum": minHum,
        "maxHum": maxHum,
        "minMoist": minMoist,
        "maxMoist": maxMoist
      };
      var requestUrl = Uri.http(baseUrl, "/devices/${device.id.toHexString()}");
      var response = await http.put(requestUrl, body: json.encode(parameters));
      print(response);
    } catch (e) {
      print(e);
    }
  }
}
