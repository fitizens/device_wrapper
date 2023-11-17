enum DeviceConnectionStatus { notConnected, connecting, connected }

enum FrequencyRate {
  r13Hz(13),
  r26Hz(26),
  r52Hz(52),
  r104Hz(104);

  const FrequencyRate(this.value);
  final int value;
}

enum AccelerometerResolution {
  g2(2),
  g4(4),
  g8(8),
  g16(16);

  const AccelerometerResolution(this.value);
  final int value;

  factory AccelerometerResolution.fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  double get idx {
    if (this == AccelerometerResolution.g2) {
      return 0;
    } else if (this == AccelerometerResolution.g4) {
      return 1;
    } else if (this == AccelerometerResolution.g8) {
      return 2;
    } else {
      return 3;
    }
  }
}

enum GyroscopeResolution {
  dps245(245),
  dps500(500),
  dps1000(1000),
  dps2000(2000);

  const GyroscopeResolution(this.value);
  final int value;

  factory GyroscopeResolution.fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  double get idx {
    if (this == GyroscopeResolution.dps245) {
      return 0;
    } else if (this == GyroscopeResolution.dps500) {
      return 1;
    } else if (this == GyroscopeResolution.dps1000) {
      return 2;
    } else {
      return 3;
    }
  }
}

enum MagnetometerResolution {
  gauss4(400),
  gauss8(800),
  gauss12(1200),
  gauss16(1600);

  const MagnetometerResolution(this.value);
  final int value;

  factory MagnetometerResolution.fromValue(int value) {
    return values.firstWhere((e) => e.value == value);
  }

  double get idx {
    if (this == MagnetometerResolution.gauss4) {
      return 0;
    } else if (this == MagnetometerResolution.gauss8) {
      return 1;
    } else if (this == MagnetometerResolution.gauss12) {
      return 2;
    } else {
      return 3;
    }
  }
}

class Device {
  String address;
  String name;

  DeviceConnectionStatus connectionStatus = DeviceConnectionStatus.notConnected;
  AccelerometerResolution accRes = AccelerometerResolution.g16;
  GyroscopeResolution gyroRes = GyroscopeResolution.dps1000;
  MagnetometerResolution magnRes = MagnetometerResolution.gauss12;

  late String serial;
  late bool isCalibrated;
  late DateTime calibrationTs;
  late Map accBias;
  late Map gyroBias;

  Device(this.name, this.address);

  @override
  bool operator ==(other) =>
      other is Device && other.address == address && other.name == name;

  @override
  int get hashCode => address.hashCode * name.hashCode;
}
