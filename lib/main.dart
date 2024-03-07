import 'dart:async';

import 'package:ble_logger/device_element.dart';
import 'package:ble_logger/extra.dart';
import 'package:ble_logger/scan_result_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const _deviceName = String.fromEnvironment('LOGGER_DEVICE_NAME');

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const BleLoggerApp());
}

class BleLoggerApp extends StatelessWidget {
  const BleLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BleDeviceScreen(),
    );
  }
}

class BleDeviceScreen extends StatefulWidget {
  const BleDeviceScreen({super.key});

  @override
  State<BleDeviceScreen> createState() => _BleDeviceScreenState();
}

class _BleDeviceScreenState extends State<BleDeviceScreen> {
  ScanResult? myScanResult;
  BluetoothDevice? myDevice;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      myScanResult = results.firstOrNull;
      if (myScanResult != null) {
        FlutterBluePlus.stopScan();
        setState(() {});
      }
    }, onError: (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.play_arrow_outlined),
        onPressed: () async {
          try {
            await FlutterBluePlus.startScan(
                timeout: const Duration(
                  seconds: 5,
                ),
                withNames: [_deviceName]);
          } catch (e, s) {
            debugPrintStack(stackTrace: s, label: e.toString());
          }
        },
      ),
      body: myScanResult != null
          ? Column(
              children: [
                ScanResultElement(
                  result: myScanResult!,
                  onTap: () {
                    myScanResult!.device
                        .connectAndUpdateStream()
                        .catchError((e, s) {
                      debugPrintStack(
                        stackTrace: s,
                        label: e.toString(),
                      );
                    });
                  },
                ),
                StreamBuilder<BluetoothConnectionState>(
                  stream: myScanResult!.device.connectionState,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data == BluetoothConnectionState.connected) {
                      return DeviceElement(
                        bluetoothDevice: myScanResult!.device,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                )
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
