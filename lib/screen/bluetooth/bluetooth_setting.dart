import 'package:flutter/material.dart';
import 'package:wifi_changer/constant.dart';
import 'package:flutter_svg/svg.dart';
import 'SelectBondedDevicePage.dart';
import 'ChatPage.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'package:wifi_changer/global-variable.dart' as globals;
import 'package:wifi_changer/screen/main/main_screen.dart';
class BluetoothSetting extends StatefulWidget {
  BluetoothSetting({
    Key? key,
  }) : super(key: key);
  @override
  _BluetoothSettingState createState() => _BluetoothSettingState();
}

class _BluetoothSettingState extends State<BluetoothSetting> {

  ValueNotifier devicesString = ValueNotifier<String>("");
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;
  BluetoothDevice selectedDevice = BluetoothDevice(name: "Non-connected",address: "0");
  bool isConnected = false;
  // BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;
  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }
  BluetoothConnection? connection;

  // void connectDevice() async{
  //   BluetoothConnection.toAddress(globals.selectedDevice.address).then((_connection) {
  //     print('Connected to the device');
  //     connection = _connection;
  //     setState(() {
  //       isConnecting = false;
  //       isDisconnecting = false;
  //     });
  //     connection!.input!.listen(_onDataReceived).onDone(() {
  //       // Example: Detect which side closed the connection
  //       // There should be `isDisconnecting` flag to show are we are (locally)
  //       // in middle of disconnecting process, should be set before calling
  //       // `dispose`, `finish` or `close`, which all causes to disconnect.
  //       // If we except the disconnection, `onDone` should be fired as result.
  //       // If we didn't except this (no flag set), it means closing by remote.
  //       if (isDisconnecting) {
  //         print('Disconnecting locally!');
  //       } else {
  //         print('Disconnected remotely!');
  //       }
  //       if (this.mounted) {
  //         setState(() {});
  //       }
  //     });
  //   }).catchError((error) {
  //     print('Cannot connect, exception occured');
  //     print(error);
  //   });
  //
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: mPrimaryColor,automaticallyImplyLeading: false,title: Text("Wifi Changer for BME Devices"),centerTitle :true),
        body:
        Container(
          child: ListView(
            children: <Widget>[
              Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(0, 20, 0,0),
                  child: Text("Setting Bluetooth",style: TextStyle(color: mPrimaryColor , fontSize: 30))
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text('Pairing Bluetooth Device',style: TextStyle(color: mPrimaryColor , fontSize: 17)),
                trailing: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(mFourthColor.withOpacity(0.8)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ))),
                  child:Text('Paired Device',style: TextStyle( color: mThirdColor )),
                  onPressed: () {
                    FlutterBluetoothSerial.instance.openSettings();
                  },
                ),
              ),
              ListTile(
                title: Text('Select Paired Device',style: TextStyle(color: mPrimaryColor,fontSize: 17)),
                trailing: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(mFourthColor.withOpacity(0.8)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ))),
                  child: Text('Select Device',style: TextStyle( color: mThirdColor )),
                  onPressed: () async {
                    final BluetoothDevice? selectedDevice =
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SelectBondedDevicePage(checkAvailability: false);
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Connect -> selected ' + selectedDevice.address);
                      globals.selectedDevice = selectedDevice ;
                      devicesString.value = selectedDevice.name.toString();
                      globals.isConnected = true;
                    } else {
                      print('Connect -> no device selected');
                    }
                  },
                ),

              ),
              Container(
                padding: const EdgeInsets.fromLTRB(17,15, 10, 0),
                child: Row(
                  children: [
                    Text("Current Devices :" ,style: TextStyle(color: mSecondaryColor, fontSize: 23)),
                    SizedBox(width: 10),
                    // Text(globals.selectedDevice.name.toString() ,style: TextStyle(color: mPrimaryColor, fontSize: 20))
                    ValueListenableBuilder(
                      //TODO 2nd: listen playerPointsToAdd
                      valueListenable: devicesString,
                      builder: (context, value, widget) {
                        //TODO here you can setState or whatever you need
                        return Text(
                          //TODO e.g.: create condition with playerPointsToAdd's value
                            value != ""
                                ? globals.selectedDevice.name.toString()
                                : "" , style: TextStyle(color: mPrimaryColor, fontSize: 20));
                      },
                    ),
                  ],
                ),

              ),
              SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                constraints: BoxConstraints.tightFor(width: 250, height: 50),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(mFourthColor.withOpacity(0.8)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ))),
                  onPressed: () {
                    if (globals.selectedDevice.address != "0") {
                      // connectDevice()
                    }
                  },
                  child: Text('Connect', style: TextStyle(color: mThirdColor, fontSize: 20)),
                ),
              )
            ],

          ),
        )

    );
  }
}

