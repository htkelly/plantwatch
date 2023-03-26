import 'package:plantwatch_flutter/models/humDateTime.dart';
import 'package:plantwatch_flutter/models/moistureDateTime.dart';
import 'package:plantwatch_flutter/models/reading.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../models/tempDateTime.dart';
import '../models/uvIndexDateTime.dart';

class SeriesHelper {
  static List<charts.Series<dynamic, DateTime>> todaysTemperatureReadings(
      List<dynamic> readings) {
    final tempDateTimes = <TempDateTime>[];
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final todaysReadings = readings.where(
        (r) => DateTime.parse(r['timestamp']).isAfter(twentyFourHoursAgo));
    for (var reading in todaysReadings) {
      tempDateTimes.add(TempDateTime(
          reading['temperature'], DateTime.parse(reading['timestamp'])));
    }
    return [
      charts.Series<TempDateTime, DateTime>(
        id: 'Temperature',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TempDateTime temperature, _) => temperature.dateTime,
        measureFn: (TempDateTime temperature, _) => temperature.temperature,
        data: tempDateTimes,
      )
    ];
  }

  static List<charts.Series<dynamic, DateTime>> todaysHumidityReadings(
      List<dynamic> readings) {
    final humDateTimes = <HumDateTime>[];
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final todaysReadings = readings.where(
        (r) => DateTime.parse(r['timestamp']).isAfter(twentyFourHoursAgo));
    for (var reading in todaysReadings) {
      humDateTimes.add(HumDateTime(
          reading['humidity'], DateTime.parse(reading['timestamp'])));
    }
    return [
      charts.Series<HumDateTime, DateTime>(
        id: 'Humidity',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (HumDateTime humidity, _) => humidity.dateTime,
        measureFn: (HumDateTime humidity, _) => humidity.humidity,
        data: humDateTimes,
      )
    ];
  }

  static List<charts.Series<dynamic, DateTime>> todaysMoistureReadings(
      List<dynamic> readings) {
    final moistureDateTimes = <MoistureDateTime>[];
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final todaysReadings = readings.where(
        (r) => DateTime.parse(r['timestamp']).isAfter(twentyFourHoursAgo));
    for (var reading in todaysReadings) {
      moistureDateTimes.add(MoistureDateTime(
          reading['moisture'], DateTime.parse(reading['timestamp'])));
    }
    return [
      charts.Series<MoistureDateTime, DateTime>(
        id: 'Moisture',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (MoistureDateTime moisture, _) => moisture.dateTime,
        measureFn: (MoistureDateTime moisture, _) => moisture.moisture,
        data: moistureDateTimes,
      )
    ];
  }

  static List<charts.Series<dynamic, DateTime>> todaysUvIndexReadings(
      List<dynamic> readings) {
    final uvIndexDateTimes = <UvIndexDateTime>[];
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final todaysReadings = readings.where(
        (r) => DateTime.parse(r['timestamp']).isAfter(twentyFourHoursAgo));
    for (var reading in todaysReadings) {
      uvIndexDateTimes.add(UvIndexDateTime(
          reading['uvIndex'], DateTime.parse(reading['timestamp'])));
    }
    return [
      charts.Series<UvIndexDateTime, DateTime>(
        id: 'Temperature',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (UvIndexDateTime uvIndex, _) => uvIndex.dateTime,
        measureFn: (UvIndexDateTime uvIndex, _) => uvIndex.uvIndex,
        data: uvIndexDateTimes,
      )
    ];
  }
}
