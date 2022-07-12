import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wifi_changer/constant.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'dart:convert';
import 'SelectBondedDevicePage.dart';
import 'ChatPage.dart';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_changer/global-variable.dart' as globals;
import 'package:wifi_changer/screen/main/main_screen.dart';
import 'package:wifi_changer/screen/wifi/wifiscan.dart';

class BluetoothSetting extends StatefulWidget {
  BluetoothSetting({
    Key? key,
  }) : super(key: key);
  @override
  _BluetoothSettingState createState() => _BluetoothSettingState();
}
class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}
class _BluetoothSettingState extends State<BluetoothSetting> {

  ValueNotifier devicesString = ValueNotifier<String>("");
  ValueNotifier checkIsConnected = ValueNotifier<bool>(false);
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;
  BluetoothDevice selectedDevice = BluetoothDevice(name: "Non-connected",address: "0");
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
  bool isConnecting = true;
  bool isDisconnecting = false;
  bool get isConnected => (connection?.isConnected ?? false);
  static final clientID = 0;
  BluetoothConnection? connection;
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';
  String stringMessage = "";
  String password = "";
  void connectDevice() async{
    BluetoothConnection.toAddress(globals.selectedDevice.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      checkIsConnected.value = connection?.isConnected ?? false;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
          checkIsConnected.value = false;
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });

  }
  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }
  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    // print(dataString);
    int index = buffer.indexOf(13);
    if (~index != 0) {

      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ?
            _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );

        if(backspacesCounter>0){
          stringMessage = _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter);
        }
        else{
          stringMessage = _messageBuffer + dataString.substring(0, index);
        }
        _messageBuffer = dataString.substring(index);

      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
  void _sendMessage(String text) async {
    print(text);
    text = text.trim();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });


      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }

  }
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
                    Text("Current Devices :" ,style: TextStyle(color: mPrimaryColor, fontSize: 23)),
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
                                : "" , style: TextStyle(color: mSecondaryColor, fontSize: 20));
                      },
                    ),
                  ],
                ),

              ),
              SizedBox(height: 20),

              Container(
                // padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                constraints: BoxConstraints.tightFor(width: 250, height: 40),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(mSecondaryColor.withOpacity(0.8)),
                      ),
                  onPressed: () {
                    if (globals.selectedDevice.address != "0") {
                      connectDevice();
                    }
                  },
                  child: Text('Connect', style: TextStyle(color: mFourthColor, fontSize: 15)),
                ),
              ),

              Container(

                padding: const EdgeInsets.fromLTRB(17,15, 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Status :" ,style: TextStyle(color: mSecondaryColor, fontSize: 23)),
                    SizedBox(width: 10),
                    // Text(globals.selectedDevice.name.toString() ,style: TextStyle(color: mPrimaryColor, fontSize: 20))
                    ValueListenableBuilder(
                      //TODO 2nd: listen playerPointsToAdd
                      valueListenable: checkIsConnected,
                      builder: (context, value, widget) {
                        //TODO here you can setState or whatever you need
                        return Text(
                          //TODO e.g.: create condition with playerPointsToAdd's value
                            value == true
                                ? "Connected"
                                : "Disconnected" , style: TextStyle(color: mPrimaryColor, fontSize: 23));
                      },
                    ),
                  ],
                ),
              )
              ,
              SizedBox(height: 10,),
              Divider(thickness: 2),
              wifiScan(),
              Form(child: Container
                (
                padding: const EdgeInsets.symmetric(vertical: 16.0,horizontal: 70),
                child: TextFormField(
                  onChanged: (val){
                    setState(() {
                      password = val;
                    });
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), hintText: 'password' , hintStyle: TextStyle(color: mSecondaryColor)
                  ),

                ),
              )),
              Container(
                margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                constraints: BoxConstraints.tightFor(width: 250, height: 40),
                child:ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(mSecondaryColor.withOpacity(0.8)),
                    ),

                  onPressed: () => _sendMessage("${globals.selectedItem},$password" "\n"),
                  child: Text('Submit',style: TextStyle(color: Colors.white , fontSize: 15)),

                ),
              )
            ],

          ),
        )

    );
  }
}


