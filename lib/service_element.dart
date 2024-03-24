import 'dart:async';

import 'package:ble_logger/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const _loggerCharacteristicUuid =
    String.fromEnvironment('LOGGER_CHARACTERISTIC_UUID');

class ServiceElement extends StatefulWidget {
  final BluetoothService service;

  const ServiceElement({
    super.key,
    required this.service,
  });

  @override
  State<ServiceElement> createState() => _ServiceElementState();
}

class _ServiceElementState extends State<ServiceElement> {
  BluetoothCharacteristic? loggerCharacteristic;
  late StreamSubscription<List<int>> _lastValueSubscription;
  late ValueNotifier<List<List<int>>> historyNotifier;
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();

    historyNotifier = ValueNotifier(History.loggerHistory);
    loggerCharacteristic = widget.service.characteristics
        .where((element) => element.uuid.str == _loggerCharacteristicUuid)
        .firstOrNull;

    if (loggerCharacteristic != null) {
      _lastValueSubscription =
          loggerCharacteristic!.lastValueStream.listen((value) {
        final newHistory = List<List<int>>.from(historyNotifier.value);
        newHistory.add(value);
        History.loggerHistory.add(value);
        historyNotifier.value = newHistory;
        scrollController.jumpTo(scrollController.position.maxScrollExtent + 20);
      });
    }
  }

  @override
  void dispose() {
    historyNotifier.dispose();
    if (loggerCharacteristic != null) {
      _lastValueSubscription.cancel();
    }
    super.dispose();
  }

  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.service.uuid.str.toUpperCase()}';
    return Text(uuid, style: const TextStyle(fontSize: 13));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Service'),
          subtitle: buildUuid(context),
          leading: buildSubscribeButton(context),
        ),
        AnimatedBuilder(
          animation: historyNotifier,
          builder: (context, _) {
            final history = historyNotifier.value;

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(left: 8),
                itemCount: history.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final data = history[index];
                  final lastItem = index == history.length - 1;
                  return Text(
                    String.fromCharCodes(data),
                    style: TextStyle(
                      fontSize: 13,
                      color: lastItem ? Colors.green : Colors.grey,
                      fontWeight: lastItem ? FontWeight.bold : null,
                    ),
                  );
                },
              ),
            );
          },
        )
      ],
    );
  }

  Widget buildSubscribeButton(BuildContext context) {
    if (loggerCharacteristic == null) {
      return const SizedBox.shrink();
    }

    final isNotifying = loggerCharacteristic!.isNotifying;
    return TextButton(
        child: Text(
          isNotifying ? "Unsubscribe" : "Subscribe",
        ),
        onPressed: () async {
          await onSubscribePressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Future onSubscribePressed() async {
    try {
      loggerCharacteristic!.isNotifying == false ? "Subscribe" : "Unubscribe";
      await loggerCharacteristic!
          .setNotifyValue(loggerCharacteristic!.isNotifying == false);
      if (loggerCharacteristic!.properties.read) {
        await loggerCharacteristic!.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
  }
}
