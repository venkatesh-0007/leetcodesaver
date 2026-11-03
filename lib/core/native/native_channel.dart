import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeChannel {
  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);

  /// Tell native Android code (AppWidget and Tile) that data has updated
  static Future<void> updateWidget({
    required int streak,
    required bool isSolvedToday,
    required int totalActiveDays,
    required String lastSync,
  }) async {
    try {
      await _channel.invokeMethod(AppConstants.methodUpdateWidget, {
        'streak': streak,
        'isSolvedToday': isSolvedToday,
        'totalActiveDays': totalActiveDays,
        'lastSync': lastSync,
      });
    } on PlatformException catch (_) {
      // In web or tests, ignore
    } catch (_) {}
  }

  /// Register callback if app was launched via Quick Settings Tile or Widget CTA
  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }
}

