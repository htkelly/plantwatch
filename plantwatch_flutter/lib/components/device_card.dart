import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:plantwatch_flutter/api/reading_api.dart';
import '../models/device.dart';
import '../models/reading.dart';

class DeviceCard extends StatefulWidget {
  DeviceCard({super.key, required this.device, required this.onTapDevice});
  Device device;
  final VoidCallback onTapDevice;

  @override
  State<StatefulWidget> createState() {
    return _DeviceCardState();
  }
}

class _DeviceCardState extends State<DeviceCard> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: ReadingApi.getReadingById(
            widget.device.latestReading.toHexString()),
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
              return GestureDetector(
                onTap: widget.onTapDevice,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  height: 220,
                  width: double.maxFinite,
                  child: Card(
                    elevation: 5,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 5),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                plantWatchIcon(),
                                SizedBox(height: 10),
                                deviceIdentifer(widget.device)
                              ],
                            ),
                            Row(
                              children: [
                                latestReading(Reading.fromMap(snapshot.data!))
                              ],
                            )
                          ],
                        )),
                  ),
                ),
              );
            }
          }
        });
  }

  Widget plantWatchIcon() {
    return const Padding(
      padding: EdgeInsets.only(left: 15.0),
      child: Align(
          alignment: Alignment.center,
          child: Icon(
            FontAwesomeIcons.seedling,
            color: Colors.green,
            size: 60,
          )),
    );
  }

  Widget deviceIdentifer(Device device) {
    return Padding(
      padding: EdgeInsets.only(left: 15.0),
      child: Align(
          alignment: Alignment.topLeft,
          child: RichText(
            text: TextSpan(
                text: device.id.toHexString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 15)),
          )),
    );
  }

  Widget latestReading(Reading reading) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Row(
          children: <Widget>[
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                text: 'Last reading: ${reading.timestamp}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
                children: <TextSpan>[
                  TextSpan(
                      text:
                          '\nTemperature: ${reading.temperature.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      )),
                  TextSpan(
                      text:
                          '\nHumidity: ${reading.humidity.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      )),
                  TextSpan(
                      text: '\nMoisture: ${reading.moisture / 10} %',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      )),
                  TextSpan(
                      text: '\nUV Index: ${reading.uvIndex}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
