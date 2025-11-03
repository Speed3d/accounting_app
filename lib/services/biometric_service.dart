// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// ✅ Hint: خدمة إدارة البصمة والتعرف البيومتري - Singleton Pattern
class BiometricService {
static final BiometricService _instance = BiometricService._internal();
BiometricService._internal();
factory BiometricService() => _instance;
static BiometricService get instance => _instance;
static const String _biometricEnabledKey = 'biometric_enabled';
final LocalAuthentication _localAuth = LocalAuthentication();
bool _isBiometricEnabled = false;
bool get isBiometricEnabled => _isBiometricEnabled;
Future<void> loadBiometricState() async {
try {
final prefs = await SharedPreferences.getInstance();
_isBiometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
} catch (e) {
debugPrint('❌ خطأ في تحميل حالة البصمة: $e');
_isBiometricEnabled = false;
}
}
/// ✅ Hint: التحقق من توفر البصمة في الجهاز (مع معالجة أخطاء المحاكي)
Future<Map<String, dynamic>> checkBiometricAvailability() async {
try {
// ✅ Hint: محاولة التحقق من دعم الجهاز
final bool isDeviceSupported = await _localAuth.isDeviceSupported();
  if (!isDeviceSupported) {
    return {
      'canCheck': false,
      'error': 'الجهاز لا يدعم البصمة',
      'isEmulatorError': false,
    };
  }

  final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
  
  if (!canCheckBiometrics) {
    return {
      'canCheck': false,
      'error': 'البصمة غير متاحة على هذا الجهاز',
      'isEmulatorError': false,
    };
  }

  final List<BiometricType> availableBiometrics = 
      await _localAuth.getAvailableBiometrics();

  if (availableBiometrics.isEmpty) {
    return {
      'canCheck': false,
      'error': 'لم يتم تسجيل أي بصمة على الجهاز',
      'isEmulatorError': false,
    };
  }

  return {
    'canCheck': true,
    'availableBiometrics': availableBiometrics,
  };
  
} on PlatformException catch (e) {
  debugPrint('❌ خطأ في فحص البصمة: $e');
  
  // ✅ Hint: التحقق إذا كان الخطأ بسبب المحاكي
  final isEmulatorError = e.code == 'channel-error' || 
                          e.message?.contains('channel') == true ||
                          e.message?.contains('Unable to establish') == true;
  
  return {
    'canCheck': false,
    'error': isEmulatorError 
        ? 'لا يمكن استخدام البصمة على المحاكي. الرجاء التجربة على جهاز حقيقي.' 
        : 'حدث خطأ أثناء فحص البصمة: ${e.message}',
    'isEmulatorError': isEmulatorError,
  };
} catch (e) {
  debugPrint('❌ خطأ غير متوقع في فحص البصمة: $e');
  return {
    'canCheck': false,
    'error': 'حدث خطأ غير متوقع: ${e.toString()}',
    'isEmulatorError': false,
  };
}
}
/// ✅ Hint: تفعيل البصمة
Future<Map<String, dynamic>> enableBiometric() async {
try {
final availability = await checkBiometricAvailability();
  if (availability['canCheck'] != true) {
    return {
      'success': false,
      'message': availability['error'],
      'isEmulatorError': availability['isEmulatorError'] ?? false,
    };
  }

  final bool didAuthenticate = await _localAuth.authenticate(
    localizedReason: 'يرجى التحقق من بصمتك لتفعيل هذه الميزة',
    options: const AuthenticationOptions(
      stickyAuth: true,
      biometricOnly: true,
    ),
  );

  if (!didAuthenticate) {
    return {
      'success': false,
      'message': 'فشل التحقق من البصمة',
      'isEmulatorError': false,
    };
  }

  _isBiometricEnabled = true;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_biometricEnabledKey, true);

  return {
    'success': true,
    'message': 'تم تفعيل البصمة بنجاح',
    'isEmulatorError': false,
  };
  
} on PlatformException catch (e) {
  debugPrint('❌ خطأ في تفعيل البصمة: $e');
  
  final isEmulatorError = e.code == 'channel-error' || 
                          e.message?.contains('channel') == true;
  
  return {
    'success': false,
    'message': isEmulatorError 
        ? 'لا يمكن استخدام البصمة على المحاكي' 
        : 'حدث خطأ: ${e.message}',
    'isEmulatorError': isEmulatorError,
  };
} catch (e) {
  debugPrint('❌ خطأ غير متوقع في تفعيل البصمة: $e');
  return {
    'success': false,
    'message': 'حدث خطأ غير متوقع: ${e.toString()}',
    'isEmulatorError': false,
  };
}
}
Future<void> disableBiometric() async {
try {
_isBiometricEnabled = false;
final prefs = await SharedPreferences.getInstance();
await prefs.setBool(_biometricEnabledKey, false);
} catch (e) {
debugPrint('❌ خطأ في إلغاء تفعيل البصمة: $e');
}
}
/// ✅ Hint: التحقق من البصمة (للاستخدام عند تسجيل الدخول)
Future<Map<String, dynamic>> authenticateWithBiometric() async {
try {
if (!_isBiometricEnabled) {
return {
'success': false,
'message': 'البصمة غير مُفعّلة',
'isEmulatorError': false,
};
}
  final availability = await checkBiometricAvailability();
  
  if (availability['canCheck'] != true) {
    return {
      'success': false,
      'message': availability['error'],
      'isEmulatorError': availability['isEmulatorError'] ?? false,
    };
  }

  final bool didAuthenticate = await _localAuth.authenticate(
    localizedReason: 'يرجى التحقق من بصمتك لتسجيل الدخول',
    options: const AuthenticationOptions(
      stickyAuth: true,
      biometricOnly: true,
    ),
  );

  if (didAuthenticate) {
    return {
      'success': true,
      'message': 'تم التحقق بنجاح',
      'isEmulatorError': false,
    };
  } else {
    return {
      'success': false,
      'message': 'فشل التحقق من البصمة',
      'isEmulatorError': false,
    };
  }
  
} on PlatformException catch (e) {
  debugPrint('❌ خطأ في التحقق من البصمة: $e');
  
  final isEmulatorError = e.code == 'channel-error' || 
                          e.message?.contains('channel') == true;
  
  return {
    'success': false,
    'message': isEmulatorError 
        ? 'لا يمكن استخدام البصمة على المحاكي' 
        : 'حدث خطأ: ${e.message}',
    'isEmulatorError': isEmulatorError,
  };
} catch (e) {
  debugPrint('❌ خطأ غير متوقع في التحقق من البصمة: $e');
  return {
    'success': false,
    'message': 'حدث خطأ غير متوقع: ${e.toString()}',
    'isEmulatorError': false,
  };
}
}
Future<void> stopAuthentication() async {
try {
await _localAuth.stopAuthentication();
} catch (e) {
debugPrint('❌ خطأ في إيقاف التحقق: $e');
}
}
}