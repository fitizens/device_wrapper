import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:data_collector/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModel extends ChangeNotifier {
  SharedPreferences? prefs;

  bool _isScanning = false;
  Set<Device> _deviceList = {};
  Set<Device> _connectedDevicesList = {};

  UnmodifiableListView<Device> get deviceList =>
      UnmodifiableListView(_deviceList);
  Set<Device> get connectedDevicesList => _connectedDevicesList;

  bool get isScanning => _isScanning;

  String get scanButtonText => _isScanning ? "Stop scan" : "Start scan";

  // void onDeviceMdsConnected(void Function(Device) cb) {
  //   _onDeviceMdsConnectedCb = cb;
  // }
  //
  // void onDeviceMdsDisconnected(void Function(Device) cb) {
  //   _onDeviceDisconnectedCb = cb;
  // }

  AppModel() {
    _initPreferences().whenComplete(() {
      prefs?.setInt("rate", prefs?.getInt("rate") ?? 13);
      notifyListeners();
    });
  }

  Future<void> _initPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  void startScan(Function onNewDeviceFound) {
    for (Device device in _deviceList) {
      if (device.connectionStatus == DeviceConnectionStatus.connected) {
        // disconnectFromDevice(device);
      }
    }
    _deviceList.clear();

    try {
      Mds.startScan((name, address) {
        // onNewDeviceFound
        Device device = Device(name, address);
        if (!_deviceList.contains(device)) {
          _deviceList.add(device);
        }
        onNewDeviceFound();
      });
      _isScanning = true;
    } on PlatformException {
      _isScanning = false;
    } finally {}
  }

  void stopScan() {
    Mds.stopScan();
    _isScanning = false;
  }

  void connectToDevice(Device device, Function onConnectedCb,
      Function onDisconnectedCb, Function onConnectionErrorCb) {
    device.connectionStatus = DeviceConnectionStatus.connecting;
    Mds.connect(
        device.address,
        // on connected
        (serial) => _onDeviceConnected(device.address, serial, onConnectedCb),
        // on disconnected
        () => _onDeviceDisconnected(device.address),
        // on connection error
        () => _onDeviceConnectError(device.address));
  }

  void disconnectFromDevice(Device device) {
    Mds.disconnect(device.address);
    _onDeviceDisconnected(device.address);
  }

  void disconnectFromDevices() {
    for (Device device in connectedDevicesList) {
      Mds.disconnect(device.address);
      _onDeviceDisconnected(device.address);
    }
  }

  void _onDeviceConnected(
      String address, String serial, Function onConnectedCb) {
    Device connectedDevice =
        _deviceList.firstWhere((element) => element.address == address);
    connectedDevice.serial = serial;

    // get IMU config parameters
    Mds.get(Mds.createRequestUri(serial, "/Meas/IMU/Config"), "{}",
        // on success
        (data, code) {
      var decodedData = jsonDecode(data);
      connectedDevice.accRes =
          AccelerometerResolution.fromValue(decodedData["Content"]["AccRange"]);
      connectedDevice.gyroRes =
          GyroscopeResolution.fromValue(decodedData["Content"]["GyroRange"]);
      connectedDevice.magnRes =
          MagnetometerResolution.fromValue(decodedData["Content"]["MagnRange"]);

      // get calibration info
      Mds.get(Mds.createRequestUri(serial, "/FTZ/Calibration/Info"), "{}",
          // on success
          (data, code) {
        if (code == 200) {
          // device is calibrated
          connectedDevice.isCalibrated = true;

          var decodedData = jsonDecode(data);
          connectedDevice.calibrationTs = DateTime.fromMillisecondsSinceEpoch(
              decodedData["Content"]["Timestamp"]);
          decodedData["Content"]["AccBias"]
              .updateAll((key, value) => value.toStringAsFixed(2));
          connectedDevice.accBias = decodedData["Content"]["AccBias"];
          decodedData["Content"]["GyroBias"]
              .updateAll((key, value) => value.toStringAsFixed(2));
          connectedDevice.gyroBias = decodedData["Content"]["GyroBias"];
        } else if (code == 204) {
          // devit calibrated
          connectedDevice.isCalibrated = false;
        }

        connectedDevice.serial = serial;
        connectedDevice.connectionStatus = DeviceConnectionStatus.connected;
        _connectedDevicesList.add(connectedDevice);

        onConnectedCb(connectedDevice);
        notifyListeners();
      },
          // on error
          (data, code) {
        disconnectFromDevice(connectedDevice);
      });
    },
        // on error
        (e, c) {
      disconnectFromDevice(connectedDevice);
    });
  }

  void _onDeviceDisconnected(String address) {
    Device foundDevice =
        _deviceList.firstWhere((element) => element.address == address);
    foundDevice.connectionStatus = DeviceConnectionStatus.notConnected;
    _connectedDevicesList.remove(foundDevice);
    notifyListeners();
    // _onDeviceDisconnectedCb.call(foundDevice);
  }

  void _onDeviceConnectError(String address) {
    _onDeviceDisconnected(address);
  }
}
