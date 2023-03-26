import 'package:flutter/material.dart';
import 'package:plantwatch_flutter/models/tempDateTime.dart';
import '../api/device_api.dart';
import '../models/device.dart';
import '../utils/seriesHelper.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DeviceChart extends StatefulWidget {
  DeviceChart({super.key, required this.device});
  Device device;
  late Function seriesFunction;

  @override
  State<StatefulWidget> createState() {
    return _DeviceChartState();
  }
}

class _DeviceChartState extends State<DeviceChart> {
  @override
  initState() {
    super.initState();
    widget.seriesFunction = SeriesHelper.todaysTemperatureReadings;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: DeviceApi.getDeviceReadings(widget.device.id.toHexString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.white,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.black,
              ),
            );
          } else {
            if (snapshot.hasError) {
              return Container(
                color: Colors.white,
                child: Center(
                    child: Text(
                  'Something went wrong, try again.',
                  style: Theme.of(context).textTheme.headline6,
                )),
              );
            } else {
              return Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  height: double.maxFinite,
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 400,
                            height: 250,
                            child: charts.TimeSeriesChart(
                                widget.seriesFunction(snapshot.data!),
                                animate: true),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.seriesFunction =
                                    SeriesHelper.todaysTemperatureReadings;
                              });
                            },
                            child: const Text("Temperature"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.seriesFunction =
                                    SeriesHelper.todaysHumidityReadings;
                              });
                            },
                            child: const Text("Humidity"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.seriesFunction =
                                    SeriesHelper.todaysMoistureReadings;
                              });
                            },
                            child: const Text("Moisture"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.seriesFunction =
                                    SeriesHelper.todaysUvIndexReadings;
                              });
                            },
                            child: const Text("UV Index"),
                          )
                        ],
                      )
                    ],
                  ));
            }
          }
        });
  }
}
