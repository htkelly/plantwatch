import 'package:flutter/material.dart';
import 'package:plantwatch_flutter/api/device_api.dart';
import 'package:plantwatch_flutter/models/device.dart';

// Define a custom Form widget.
class AddDeviceForm extends StatefulWidget {
  AddDeviceForm({super.key});

  @override
  AddDeviceFormState createState() {
    return AddDeviceFormState();
  }
}

class AddDeviceFormState extends State<AddDeviceForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController deviceAddController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: deviceAddController,
            decoration: const InputDecoration(labelText: "Device ID"),
            keyboardType: TextInputType.text,
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
                DeviceApi.addDeviceToAccount(deviceAddController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
