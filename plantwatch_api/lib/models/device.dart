import 'package:mongo_dart/mongo_dart.dart';

class Device {
  final ObjectId id;
  final String timestamp;
  final ObjectId latestReading;

  Device(this.id, this.timestamp, this.latestReading);

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'timestamp': timestamp,
      'latestReading': latestReading,
    };
  }

  Device.fromMap(Map<String, dynamic> map)
      : id = ObjectId.fromHexString(map['_id']),
        timestamp = map['timestamp'],
        latestReading = ObjectId.fromHexString(map['latestReading']);
}
