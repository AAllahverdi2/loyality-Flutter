import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Real Device ID-ni əldə edir (Android ID, iOS identifierForVendor, Windows deviceId və s.)
  static Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'web_browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_device';
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        return winInfo.deviceId;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'macos_device';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? 'linux_device';
      }
    } catch (e) {
      debugPrint('Device ID tapılarkən xəta: $e');
    }
    return 'unknown_device_id';
  }

  /// Real Device Name-i əldə edir (Məsələn: "Samsung SM-S908B", "iPhone 14 Pro", "Lenovo-PC" və s.)
  static Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.browserName.name;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        return winInfo.computerName;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return macInfo.computerName;
      }
    } catch (e) {
      debugPrint('Device Name tapılarkən xəta: $e');
    }
    return 'Flutter Device';
  }
}
