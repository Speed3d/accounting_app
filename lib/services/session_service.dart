// lib/services/session_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===========================================================================
/// 🎯 خدمة إدارة الجلسة - النظام الجديد المبسط
/// ===========================================================================
///
/// ← Hint: هذه الخدمة تحل محل نظام Users المحلي بالكامل
/// ← Hint: Firebase Auth هو مصدر الحقيقة، نحن فقط نحفظ البيانات الأساسية محلياً
/// ← Hint: كل البيانات تُخزن في SharedPreferences (بسيط ولا يُحذف في Hot Restart)
///
/// ===========================================================================

class SessionService {
  // ==========================================================================
  // Singleton Pattern
  // ==========================================================================

  static final SessionService _instance = SessionService._internal();
  SessionService._internal();
  factory SessionService() => _instance;
  static SessionService get instance => _instance;

  // ==========================================================================
  // ← Hint: مفاتيح التخزين في SharedPreferences
  // ==========================================================================

  static const String _keyEmail = 'session_user_email';
  static const String _keyDisplayName = 'session_user_display_name';
  static const String _keyPhotoURL = 'session_user_photo_url';
  static const String _keyIsLoggedIn = 'session_is_logged_in';
  static const String _keyLoginTimestamp = 'session_login_timestamp';

  // ==========================================================================
  // ← Hint: Cache في الذاكرة لتحسين الأداء
  // ==========================================================================

  String? _cachedEmail;
  String? _cachedDisplayName;
  String? _cachedPhotoURL;

  // ==========================================================================
  // 1️⃣ حفظ الجلسة بعد تسجيل الدخول الناجح
  // ← Hint: يُستدعى من register_screen و login_screen بعد Firebase Auth
  // ==========================================================================

  /// حفظ معلومات المستخدم في الجلسة
  ///
  /// ← Hint: email - البريد الإلكتروني (إجباري - Primary Key)
  /// ← Hint: displayName - الاسم الكامل (اختياري - من Firebase User)
  /// ← Hint: photoURL - رابط الصورة (اختياري - من Firebase Storage أو Gravatar)
  Future<void> saveSession({
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      debugPrint('💾 [SessionService] حفظ الجلسة لـ: $email');

      final prefs = await SharedPreferences.getInstance();

      // ← Hint: حفظ البيانات في SharedPreferences
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyDisplayName, displayName ?? '');
      await prefs.setString(_keyPhotoURL, photoURL ?? '');
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(
        _keyLoginTimestamp,
        DateTime.now().toIso8601String(),
      );

      // ← Hint: تحديث الـ Cache
      _cachedEmail = email;
      _cachedDisplayName = displayName;
      _cachedPhotoURL = photoURL;

      debugPrint('✅ [SessionService] تم حفظ الجلسة بنجاح');
    } catch (e) {
      debugPrint('❌ [SessionService] خطأ في حفظ الجلسة: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 2️⃣ الحصول على Email (Primary Identifier)
  // ← Hint: يُستخدم للتحقق من وجود جلسة في splash_screen
  // ==========================================================================

  /// الحصول على Email المستخدم الحالي
  ///
  /// ← Hint: إذا عاد null → المستخدم غير مسجل دخول → RegisterScreen
  /// ← Hint: إذا عاد email → تسجيل دخول تلقائي عبر Firebase Auth
  Future<String?> getEmail() async {
    try {
      // ← Hint: أولاً: التحقق من الـ Cache (أسرع)
      if (_cachedEmail != null) {
        return _cachedEmail;
      }

      // ← Hint: ثانياً: القراءة من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_keyEmail);

      // ← Hint: تحديث الـ Cache
      _cachedEmail = email;

      return email;
    } catch (e) {
      debugPrint('⚠️ [SessionService] خطأ في قراءة Email: $e');
      return null;
    }
  }

  // ==========================================================================
  // 3️⃣ الحصول على الاسم الكامل
  // ← Hint: يُستخدم في القائمة الجانبية والشريط العلوي
  // ==========================================================================

  /// الحصول على الاسم الكامل للمستخدم
  ///
  /// ← Hint: إذا فارغ → عرض Email بدلاً منه
  Future<String?> getDisplayName() async {
    try {
      // ← Hint: Cache أولاً
      if (_cachedDisplayName != null && _cachedDisplayName!.isNotEmpty) {
        return _cachedDisplayName;
      }

      // ← Hint: SharedPreferences ثانياً
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyDisplayName);

      // ← Hint: تحديث Cache
      _cachedDisplayName = name;

      return (name != null && name.isNotEmpty) ? name : null;
    } catch (e) {
      debugPrint('⚠️ [SessionService] خطأ في قراءة DisplayName: $e');
      return null;
    }
  }

  // ==========================================================================
  // 4️⃣ الحصول على رابط الصورة
  // ← Hint: يُستخدم في القائمة الجانبية (دائرة الصورة)
  // ==========================================================================

  /// الحصول على رابط صورة المستخدم
  ///
  /// ← Hint: إذا null → عرض أيقونة افتراضية
  Future<String?> getPhotoURL() async {
    try {
      // ← Hint: Cache
      if (_cachedPhotoURL != null && _cachedPhotoURL!.isNotEmpty) {
        return _cachedPhotoURL;
      }

      // ← Hint: SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_keyPhotoURL);

      // ← Hint: تحديث Cache
      _cachedPhotoURL = url;

      return (url != null && url.isNotEmpty) ? url : null;
    } catch (e) {
      debugPrint('⚠️ [SessionService] خطأ في قراءة PhotoURL: $e');
      return null;
    }
  }

  // ==========================================================================
  // 5️⃣ التحقق من وجود جلسة نشطة
  // ← Hint: يُستخدم في splash_screen لتحديد التنقل
  // ==========================================================================

  /// التحقق من وجود جلسة نشطة
  ///
  /// ← Hint: true → المستخدم مسجل دخول → فحص Firebase
  /// ← Hint: false → المستخدم غير مسجل → RegisterScreen
  Future<bool> hasActiveSession() async {
    try {
      final email = await getEmail();

      // ← Hint: إذا يوجد Email → يوجد جلسة
      return email != null && email.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ [SessionService] خطأ في فحص الجلسة: $e');
      return false;
    }
  }

  // ==========================================================================
  // 6️⃣ تحديث الاسم (بعد تغييره من الإعدادات)
  // ← Hint: يُستدعى من profile_settings_screen بعد Firebase updateProfile
  // ==========================================================================

  /// تحديث الاسم الكامل في الجلسة
  ///
  /// ← Hint: يجب تحديثه في Firebase أولاً، ثم هنا
  Future<void> updateDisplayName(String newDisplayName) async {
    try {
      debugPrint('🔄 [SessionService] تحديث الاسم إلى: $newDisplayName');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDisplayName, newDisplayName);

      // ← Hint: تحديث الـ Cache
      _cachedDisplayName = newDisplayName;

      debugPrint('✅ [SessionService] تم تحديث الاسم بنجاح');
    } catch (e) {
      debugPrint('❌ [SessionService] خطأ في تحديث الاسم: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 7️⃣ تحديث الصورة (بعد رفعها لـ Firebase Storage)
  // ← Hint: يُستدعى من profile_settings_screen بعد رفع الصورة
  // ==========================================================================

  /// تحديث رابط صورة المستخدم
  ///
  /// ← Hint: الصورة يجب رفعها لـ Firebase Storage أولاً والحصول على URL
  Future<void> updatePhotoURL(String newPhotoURL) async {
    try {
      debugPrint('🔄 [SessionService] تحديث الصورة إلى: $newPhotoURL');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPhotoURL, newPhotoURL);

      // ← Hint: تحديث الـ Cache
      _cachedPhotoURL = newPhotoURL;

      debugPrint('✅ [SessionService] تم تحديث الصورة بنجاح');
    } catch (e) {
      debugPrint('❌ [SessionService] خطأ في تحديث الصورة: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 8️⃣ مسح الجلسة (Logout)
  // ← Hint: يُستدعى عند تسجيل الخروج من القائمة الجانبية
  // ==========================================================================

  /// مسح الجلسة الحالية (تسجيل خروج)
  ///
  /// ← Hint: يجب استدعاء Firebase Auth.signOut() أولاً، ثم هذه الدالة
  Future<void> clearSession() async {
    try {
      debugPrint('🗑️ [SessionService] مسح الجلسة...');

      final prefs = await SharedPreferences.getInstance();

      // ← Hint: حذف كل البيانات من SharedPreferences
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyDisplayName);
      await prefs.remove(_keyPhotoURL);
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyLoginTimestamp);

      // ← Hint: مسح الـ Cache
      _cachedEmail = null;
      _cachedDisplayName = null;
      _cachedPhotoURL = null;

      debugPrint('✅ [SessionService] تم مسح الجلسة بنجاح');
    } catch (e) {
      debugPrint('❌ [SessionService] خطأ في مسح الجلسة: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 9️⃣ دوال مساعدة (للتشخيص)
  // ==========================================================================

  /// الحصول على كل بيانات الجلسة (للتشخيص)
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'email': prefs.getString(_keyEmail),
        'displayName': prefs.getString(_keyDisplayName),
        'photoURL': prefs.getString(_keyPhotoURL),
        'isLoggedIn': prefs.getBool(_keyIsLoggedIn) ?? false,
        'loginTimestamp': prefs.getString(_keyLoginTimestamp),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// طباعة معلومات الجلسة للتشخيص
  Future<void> debugPrintSession() async {
    final info = await getSessionInfo();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 [SessionService] معلومات الجلسة:');
    debugPrint('   Email: ${info['email']}');
    debugPrint('   DisplayName: ${info['displayName']}');
    debugPrint('   PhotoURL: ${info['photoURL']}');
    debugPrint('   IsLoggedIn: ${info['isLoggedIn']}');
    debugPrint('   LoginTimestamp: ${info['loginTimestamp']}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
