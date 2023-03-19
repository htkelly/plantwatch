import 'package:mongo_dart/mongo_dart.dart';

class Reading {
  final ObjectId id;
  final ObjectId deviceId;
  final String timestamp;
  final double temperature;
  final double humidity;
  final int moisture;
  final double uvIndex;

  Reading(this.id, this.deviceId, this.timestamp, this.temperature,
      this.humidity, this.moisture, this.uvIndex);

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'deviceId': deviceId,
      'timestamp': temperature,
      'temperature': temperature,
      'humidity': humidity,
      'moisture': moisture,
      'uvIndex': uvIndex,
    };
  }

  Reading.fromMap(Map<String, dynamic> map)
      : id = ObjectId.fromHexString(map['_id']),
        deviceId = ObjectId.fromHexString(map['deviceId']),
        timestamp = map['timestamp'],
        temperature = map['temperature'],
        humidity = map['humidity'],
        moisture = map['moisture'],
        uvIndex = map['uvIndex'];
}
