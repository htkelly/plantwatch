import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:plantwatch_flutter/api/device_api.dart';
import 'package:plantwatch_flutter/models/device.dart';
import 'package:plantwatch_flutter/components/device_card.dart';
import 'package:plantwatch_flutter/pages/add_device.dart';
import 'package:plantwatch_flutter/pages/viewdevice.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: DeviceApi.getUserDevices(),
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
                  ),
                ),
              );
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text("Plantwatch Dashboard"),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<ProfileScreen>(
                            builder: (context) => ProfileScreen(
                              appBar: AppBar(
                                title: const Text('Plantwatch Profile'),
                              ),
                              actions: [
                                SignedOutAction((context) {
                                  Navigator.of(context).pop();
                                })
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return DeviceAdd();
                            },
                          ),
                        ).then((_) => setState(() {}));
                      },
                    )
                  ],
                  automaticallyImplyLeading: false,
                ),
                body: ListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DeviceCard(
                        device: Device.fromMap(snapshot.data![index]),
                        onTapDevice: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return DeviceDetails();
                              },
                              settings: RouteSettings(
                                arguments:
                                    Device.fromMap(snapshot.data![index]),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  itemCount: snapshot.data!.length,
                ),
              );
            }
          }
        });
  }
}
