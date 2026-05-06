import 'package:safe_device/safe_device.dart';

Future<bool> isMockLocationFlagged() async {
  try {
    return await SafeDevice.isMockLocation;
  } catch (_) {
    return false;
  }
}

Future<bool> isDeviceSafe() async {
  try {
    return await SafeDevice.isSafeDevice;
  } catch (_) {
    return true;
  }
}
