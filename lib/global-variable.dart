library my_prj.globals;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


bool isLoggedIn = false;
BluetoothDevice selectedDevice = BluetoothDevice(name: "Non-connected",address: "0") ;
String selectedItem = 'Wifi not Found';
bool isConnected = false;
bool changeToText = false;
bool isStartMeasure =false;
String pathUser = "";
String pathTest = "";
int deviceId = 1 ;
String FileName = "user";