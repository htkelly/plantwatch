import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/device.dart';
import '../models/reading.dart';

var baseUrl = dotenv.env['PLANTWATCH_API_HOST']!;

class ReadingApi {
  static Future<List<Map<String, dynamic>>> getReadings() async {
    try {
      var requestUrl = Uri.http(baseUrl, "/readings");
      var response = await http.get(requestUrl);
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<Map<String, dynamic>>>?);
    }
  }

  static Future<Map<String, dynamic>?> getReadingById(String id) async {
    try {
      var requestUrl = Uri.http(baseUrl, "/readings/${id}");
      var response = await http.get(requestUrl);
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<Map<String, dynamic>?>?);
    }
  }
}
