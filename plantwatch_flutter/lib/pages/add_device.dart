import 'package:flutter/material.dart';
import 'package:plantwatch_flutter/models/device.dart';

import '../components/add_device_form.dart';
import '../components/parameters_form.dart';

class DeviceAdd extends StatefulWidget {
  @override
  _DeviceAddState createState() => _DeviceAddState();
}

class _DeviceAddState extends State<DeviceAdd> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var widgetText = 'Add device';
    return Scaffold(
        appBar: AppBar(
          title: Text('Add device'),
        ),
        body: AddDeviceForm());
  }
}
