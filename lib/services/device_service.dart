// lib/services/device_service.dart

// Hint: استيراد الحزم اللازمة.
import 'dart:io'; // للتحقق من نظام التشغيل (Platform.isAndroid)
import 'package:device_info_plus/device_info_plus.dart';

/// خدمة متخصصة لجلب معلومات الجهاز.
/// وظيفتها الوحيدة هي توفير معرف فريد ومستقر للجهاز.
class DeviceService {
  // Hint: نستخدم Singleton Pattern لضمان وجود نسخة واحدة فقط من هذه الخدمة في التطبيق.
  DeviceService._privateConstructor();
  static final DeviceService instance = DeviceService._privateConstructor();

  // Hint: كائن للوصول إلى معلومات الجهاز من الحزمة.
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// دالة غير متزامنة لجلب "بصمة الجهاز" الفريدة.
  /// سلسلة نصية (String) تمثل المعرف الفريد للجهاز.
  /// في حالة الفشل، تعيد رسالة خطأ.
  Future<String> getDeviceFingerprint() async {
    try {
      // Hint: نتحقق من أننا نعمل على نظام أندرويد.
      // يمكن إضافة منطق لأنظمة أخرى (مثل iOS) هنا في المستقبل.
      if (Platform.isAndroid) {
        // جلب معلومات جهاز الأندرويد.
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        
        // --- ✅ هذا هو المعرف الرئيسي الذي سنعتمد عليه ---
        // androidId: هو معرف فريد مكون من 64 بت يتم إنشاؤه عند أول إقلاع للجهاز.
        // يبقى ثابتاً طوال عمر الجهاز ما لم يتم عمل إعادة ضبط المصنع.
        final String? androidId = androidInfo.id;

        if (androidId != null && androidId.isNotEmpty) {
          // Hint: نعيد المعرف بعد تحويله إلى حروف كبيرة (Uppercase) لتوحيد الشكل.
          // ونضيف بادئة "AND-" لتمييزه كمعرف أندرويد.
          return 'AND-${androidId.toUpperCase()}';
        } else {
          // حالة نادرة جداً: إذا فشل النظام في توفير المعرف.
          return 'UNKNOWN_ANDROID_ID';
        }
      } 
      // --- يمكنك إضافة `else if (Platform.isIOS)` هنا لدعم iOS ---
      else {
        // إذا كان النظام غير مدعوم حالياً.
        return 'UNSUPPORTED_PLATFORM';
      }
    } catch (e) {
      // في حالة حدوث أي خطأ أثناء جلب المعلومات.
      print('Error getting device fingerprint: $e');
      return 'ERROR_GETTING_ID';
    }
  }
}
