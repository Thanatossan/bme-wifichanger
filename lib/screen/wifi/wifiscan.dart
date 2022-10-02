import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_changer/constant.dart';
import 'package:wifi_changer/global-variable.dart' as globals;
class wifiScan extends StatefulWidget {
  const wifiScan({Key? key}) : super(key: key);

  @override
  _wifiScanState createState() => _wifiScanState();
}

class _wifiScanState extends State<wifiScan> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  List<String> listSSID = <String>[];

  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  Future<void> _startScan(BuildContext context) async {
    final result = await WiFiScan.instance.startScan(askPermissions: true);

    setState(() => accessPoints = <WiFiAccessPoint>[]);
  }
  void _getScannedResults(BuildContext context) async {
    // get scanned results
    final results = await WiFiScan.instance.getScannedResults(askPermissions: true);

    setState(() => accessPoints = results.value!);
    setState(() => listSSID = results.value!.map((accessPoint) => accessPoint.ssid).toList());

  }


  //TODO must test
  void startAndScan(BuildContext context) async {
      _startScan(context);
      listSSID = [];
      _getScannedResults(context);
  }

  final _formKey = GlobalKey<FormState>();
  String password = "";
  @override
  Widget build(BuildContext context) {
    return Container(
      child :Column(
        children: [
          SizedBox(height: 10,),
          Text("Setting Wifi",style: TextStyle(color: mPrimaryColor , fontSize: 30)),
          SizedBox(height: 10),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     ElevatedButton.icon(
          //
          //       icon: const Icon(Icons.perm_scan_wifi),
          //       label: const Text('SCAN'),
          //       onPressed: () async => _startScan(context),
          //       style: ElevatedButton.styleFrom(primary: mSecondaryColor),
          //     ),
          //     SizedBox(width: 20),
          //     ElevatedButton.icon(
          //       icon: const Icon(Icons.refresh),
          //       label: const Text('GET'),
          //       onPressed: () async => _getScannedResults(context),
          //       style: ElevatedButton.styleFrom(primary: mSecondaryColor),
          //     ),
          //
          //   ],
          // ),
          ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('GET WIFI'),
                onPressed: () async => startAndScan(context),
                style: ElevatedButton.styleFrom(primary: mSecondaryColor),
              ),

          SizedBox(height: 20,),
          listSSID.isEmpty? Text("NO SCANNED RESULTS", style: TextStyle(color: mSecondaryColor,fontSize: 23),):
              DropdownButton(

                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style:  TextStyle(color: mSecondaryColor,fontSize: 20),
                  underline: Container(
                    height: 2,
                    color: mSecondaryColor,
                  ),

                  items: listSSID.map((ssid) =>
              DropdownMenuItem(child: Text(ssid) , value: ssid)
              ).toList(),
                  value: globals.selectedItem == 'Wifi not Found'?listSSID[0]:globals.selectedItem,
                  selectedItemBuilder: (BuildContext context){
                return listSSID.map<Widget>((ssid){
                  return Text(ssid);
                }).toList();
              },onChanged: (String? ssid)=> setState(
                      ()=> globals.selectedItem = ssid!

              )),

        ],

      )


    );
  }
}
