import 'package:flutter/material.dart';
import 'package:plantwatch_flutter/components/chart.dart';
import 'package:plantwatch_flutter/models/device.dart';

import '../components/parameters_form.dart';

class DeviceDetails extends StatefulWidget {
  @override
  _DeviceDetailsState createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<DeviceDetails> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Device device = ModalRoute.of(context)!.settings.arguments as Device;
    var widgetText = 'Device details';
    return Scaffold(
        appBar: AppBar(
          title: Text(device.id.toHexString()),
        ),
        body: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 800,
                  height: 400,
                  child: DeviceChart(device: device),
                )
              ],
            ),
            Row(
              children: [
                SizedBox(
                    width: 400,
                    height: 400,
                    child: ParametersForm(device: device))
              ],
            )
          ],
        ));
  }
}
