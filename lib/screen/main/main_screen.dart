import 'package:flutter/material.dart';
import 'package:wifi_changer/constant.dart';
import 'package:wifi_changer/screen/bluetooth/bluetooth_setting.dart';
import 'package:wifi_changer/screen/wifi/wifiscan.dart';
class mainScreen extends StatefulWidget {
  const mainScreen({Key? key}) : super(key: key);

  @override
  _mainScreenState createState() => _mainScreenState();
}

class _mainScreenState extends State<mainScreen> {
  @override
  Widget build(BuildContext context) {
    return BluetoothSetting();
  }
}
