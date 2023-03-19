import 'dart:async';
import 'dart:ffi';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/device.dart';
import '../utils/constants.dart';

class MongoDatabase {
  static var db, deviceCollection, readingCollection;

  static connect() async {
    db = await Db.create(dotenv.env['MONGO_CONN_URL']!);
    await db.open();
    deviceCollection = db.collection(DEVICE_COLLECTION);
    readingCollection = db.collection(READING_COLLECTION);
  }

  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final devices = await deviceCollection.find().toList();
      return devices;
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<Map<String, dynamic>>>?);
    }
  }

  static Future<List<Map<String, dynamic>>> getReadings() async {
    try {
      final readings = await readingCollection.find().toList();
      return readings;
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<List<Map<String, dynamic>>>?);
    }
  }

  static Future<Map<String, dynamic>?> getReadingById(ObjectId id) async {
    try {
      final reading =
          await readingCollection.findOne(where.eq("_id", id.toHexString()));
      return reading;
    } catch (e) {
      print(e);
      return Future.value(e as FutureOr<Map<String, dynamic>?>?);
    }
  }

  static setParameters(Device device, double minTemp, double maxTemp,
      double minHum, double maxHum, double minMoist, double maxMoist) async {
    var _device = await deviceCollection
        .findOne(where.eq("_id", device.id.toHexString()));
    var parameters = {
      "minTemp": minTemp,
      "maxTemp": maxTemp,
      "minHum": minHum,
      "maxHum": maxHum,
      "minMoist": minMoist,
      "maxMoist": maxMoist
    };
    _device["parameters"] = parameters;
    await deviceCollection.save(_device);
  }
}
