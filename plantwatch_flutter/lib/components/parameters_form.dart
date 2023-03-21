import 'package:flutter/material.dart';
import 'package:plantwatch_flutter/api/device_api.dart';
import 'package:plantwatch_flutter/models/device.dart';

// Define a custom Form widget.
class ParametersForm extends StatefulWidget {
  ParametersForm({super.key, required this.device});
  Device device;

  @override
  ParametersFormState createState() {
    return ParametersFormState();
  }
}

class ParametersFormState extends State<ParametersForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController minTempController = TextEditingController();
  TextEditingController maxTempController = TextEditingController();
  TextEditingController minHumController = TextEditingController();
  TextEditingController maxHumController = TextEditingController();
  TextEditingController minMoistController = TextEditingController();
  TextEditingController maxMoistController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: minTempController,
            decoration: const InputDecoration(labelText: "MinTemp"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          TextFormField(
            controller: maxTempController,
            decoration: const InputDecoration(labelText: "MaxTemp"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          TextFormField(
            controller: minHumController,
            decoration: const InputDecoration(labelText: "MinHum"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          TextFormField(
            controller: maxHumController,
            decoration: const InputDecoration(labelText: "MaxHum"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          TextFormField(
            controller: minMoistController,
            decoration: const InputDecoration(labelText: "MinMoist"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          TextFormField(
            controller: maxMoistController,
            decoration: const InputDecoration(labelText: "MaxMoist"),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              // Validate returns true if the form is valid, or false otherwise.
              if (_formKey.currentState!.validate()) {
                // If the form is valid, display a snackbar. In the real world,
                // you'd often call a server or save the information in a database.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing Data')),
                );
                DeviceApi.setDeviceParameters(
                    widget.device,
                    double.parse(minTempController.text),
                    double.parse(maxTempController.text),
                    double.parse(minHumController.text),
                    double.parse(maxHumController.text),
                    double.parse(minMoistController.text),
                    double.parse(maxMoistController.text));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
