import 'package:ble_logger/service_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const _serviceUuid = String.fromEnvironment('LOGGER_SERVICE_UUID');

class DeviceElement extends StatefulWidget {
  const DeviceElement({
    super.key,
    required this.bluetoothDevice,
  });
  final BluetoothDevice bluetoothDevice;

  @override
  State<DeviceElement> createState() => _DeviceElementState();
}

class _DeviceElementState extends State<DeviceElement> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BluetoothService>>(
      future: widget.bluetoothDevice.discoverServices(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final services = snapshot.data!;
          final service = services
              .where(
                (element) => element.serviceUuid.str == _serviceUuid,
              )
              .firstOrNull;
          if (service != null) return ServiceElement(service: service);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
