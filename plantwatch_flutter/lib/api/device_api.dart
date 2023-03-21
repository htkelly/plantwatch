import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
