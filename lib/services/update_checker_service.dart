// lib/services/update_checker_service.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_service.dart';

// ============================================================================
// 🔄 خدمة التحقق من التحديثات - Singleton Pattern
// ============================================================================
//
// ← Hint: تستخدم Firebase Remote Config للتحقق من الإصدار الأحدث
// ← Hint: تقارن بين إصدار التطبيق الحالي والإصدار الأحدث
// ← Hint: تعرض حوار تحديث للمستخدم إذا كان هناك تحديث متاح
//
// استخدام في splash_screen.dart أو main_screen.dart:
// ```dart
// final updateInfo = await UpdateCheckerService.instance.checkForUpdates();
// if (updateInfo.hasUpdate) {
//   UpdateCheckerService.instance.showUpdateDialog(context, updateInfo);
// }
// ```
//
// ============================================================================

/// 📦 معلومات التحديث
class UpdateInfo {
  final String currentVersion;     // ← الإصدار الحالي للتطبيق
  final String latestVersion;      // ← آخر إصدار متاح
  final bool hasUpdate;            // ← هل يوجد تحديث؟
  final bool isMandatory;          // ← هل التحديث إجباري؟
  final String? updateMessage;     // ← رسالة التحديث (اختياري)
  final String? downloadUrl;       // ← رابط التحميل (اختياري)

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    this.isMandatory = false,
    this.updateMessage,
    this.downloadUrl,
  });
}

// ============================================================================
// 🔄 خدمة التحقق من التحديثات - Singleton
// ============================================================================
class UpdateCheckerService {
  // ← Hint: Singleton Pattern
  static final UpdateCheckerService _instance = UpdateCheckerService._internal();
  UpdateCheckerService._internal();
  factory UpdateCheckerService() => _instance;
  static UpdateCheckerService get instance => _instance;

  // ← Hint: Cache للتحقق (مرة واحدة في الجلسة)
  UpdateInfo? _cachedUpdateInfo;
  bool _hasChecked = false;

  // ==========================================================================
  // ← Hint: التحقق من التحديثات
  // ==========================================================================
  /// 🔍 التحقق من وجود تحديثات جديدة
  ///
  /// ← Hint: يقارن الإصدار الحالي مع Firebase Remote Config
  /// ← Hint: يُنفذ مرة واحدة في الجلسة (Cache)
  ///
  /// المفاتيح في Firebase Remote Config:
  /// - `app_latest_version` (String): رقم الإصدار الأحدث (مثل "1.2.0")
  /// - `app_force_update` (Boolean): هل التحديث إجباري؟
  /// - `update_message_ar` (String): رسالة التحديث بالعربية
  /// - `update_message_en` (String): رسالة التحديث بالإنجليزية
  /// - `update_url_android` (String): رابط التحديث لأندرويد
  /// - `update_url_ios` (String): رابط التحديث لـ iOS
  Future<UpdateInfo> checkForUpdates() async {
    // ← Hint: إذا تم الفحص مسبقاً في هذه الجلسة
    if (_hasChecked && _cachedUpdateInfo != null) {
      debugPrint('ℹ️ [UpdateChecker] استخدام Cache - تم الفحص مسبقاً');
      return _cachedUpdateInfo!;
    }

    try {
      debugPrint('🔍 [UpdateChecker] التحقق من التحديثات...');

      // ← Hint: 1️⃣ الحصول على الإصدار الحالي من التطبيق
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('📱 [UpdateChecker] الإصدار الحالي: $currentVersion');

      // ← Hint: 2️⃣ الحصول على آخر إصدار من Firebase
      final firebaseService = FirebaseService.instance;
      final remoteConfig = firebaseService.remoteConfig;

      // ← Hint: تأكد من تحميل الإعدادات أولاً
      await firebaseService.forceRefreshConfig();

      final latestVersion = remoteConfig.getString('app_latest_version');
      final forceUpdate = remoteConfig.getBool('app_force_update');
      final updateMessageAr = remoteConfig.getString('update_message_ar');
      final updateUrlAndroid = remoteConfig.getString('update_url_android');

      debugPrint('☁️ [UpdateChecker] آخر إصدار: $latestVersion');
      debugPrint('⚠️ [UpdateChecker] تحديث إجباري: $forceUpdate');

      // ← Hint: 3️⃣ مقارنة الإصدارات
      final hasUpdate = _compareVersions(currentVersion, latestVersion);

      // ← Hint: 4️⃣ بناء معلومات التحديث
      final updateInfo = UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        hasUpdate: hasUpdate,
        isMandatory: forceUpdate,
        updateMessage: updateMessageAr.isNotEmpty ? updateMessageAr : null,
        downloadUrl: updateUrlAndroid.isNotEmpty ? updateUrlAndroid : null,
      );

      // ← Hint: حفظ في الـ Cache
      _cachedUpdateInfo = updateInfo;
      _hasChecked = true;

      if (hasUpdate) {
        debugPrint('✅ [UpdateChecker] يوجد تحديث جديد: $latestVersion');
      } else {
        debugPrint('✅ [UpdateChecker] التطبيق محدّث - لا يوجد تحديث');
      }

      return updateInfo;
    } catch (e) {
      debugPrint('❌ [UpdateChecker] خطأ في التحقق من التحديثات: $e');

      // ← Hint: في حالة الخطأ، نُرجع معلومات فارغة
      final packageInfo = await PackageInfo.fromPlatform();
      return UpdateInfo(
        currentVersion: packageInfo.version,
        latestVersion: packageInfo.version,
        hasUpdate: false,
      );
    }
  }

  // ==========================================================================
  // ← Hint: مقارنة الإصدارات (semantic versioning)
  // ==========================================================================
  /// 🔢 مقارنة رقمي إصدار
  ///
  /// ← Hint: يدعم تنسيق Semantic Versioning (مثل "1.2.3")
  /// ← Hint: يُرجع true إذا كان latestVersion أحدث من currentVersion
  ///
  /// أمثلة:
  /// - "1.0.0" < "1.1.0" → true
  /// - "1.2.0" < "1.2.1" → true
  /// - "2.0.0" < "1.9.9" → false
  bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      // ← Hint: تحويل النسخ إلى قوائم أرقام
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();

      // ← Hint: مقارنة كل رقم على حدة (major.minor.patch)
      for (int i = 0; i < 3; i++) {
        final currentPart = i < current.length ? current[i] : 0;
        final latestPart = i < latest.length ? latest[i] : 0;

        if (latestPart > currentPart) {
          return true; // ← يوجد تحديث
        } else if (latestPart < currentPart) {
          return false; // ← الإصدار الحالي أحدث (غير متوقع)
        }
        // ← إذا كانت متساوية، نكمل للرقم التالي
      }

      // ← Hint: الإصدارات متطابقة
      return false;
    } catch (e) {
      debugPrint('❌ [UpdateChecker] خطأ في مقارنة الإصدارات: $e');
      return false;
    }
  }

  // ==========================================================================
  // ← Hint: عرض حوار التحديث
  // ==========================================================================
  /// 📢 عرض حوار التحديث للمستخدم
  ///
  /// ← Hint: يعرض رسالة مخصصة مع زر التحديث
  /// ← Hint: إذا كان التحديث إجباري → لا يمكن إغلاق الحوار
  void showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo, {
    String? customMessage,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isMandatory, // ← لا يمكن إغلاقه إذا كان إجباري
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          // ← Hint: منع الإغلاق بزر الرجوع إذا كان إجباري
          onWillPop: () async => !updateInfo.isMandatory,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  updateInfo.isMandatory
                      ? Icons.warning_amber_rounded
                      : Icons.system_update,
                  color: updateInfo.isMandatory ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    updateInfo.isMandatory
                        ? (isArabic ? 'تحديث مطلوب' : 'Update Required')
                        : (isArabic ? 'تحديث متاح' : 'Update Available'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ← Hint: الرسالة المخصصة أو الافتراضية
                Text(
                  customMessage ??
                      updateInfo.updateMessage ??
                      (isArabic
                          ? 'يوجد إصدار جديد من التطبيق (${updateInfo.latestVersion})'
                          : 'A new version is available (${updateInfo.latestVersion})'),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),

                // ← Hint: معلومات الإصدار
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildVersionRow(
                        isArabic ? 'الإصدار الحالي' : 'Current Version',
                        updateInfo.currentVersion,
                        Icons.smartphone,
                      ),
                      const SizedBox(height: 8),
                      _buildVersionRow(
                        isArabic ? 'الإصدار الجديد' : 'New Version',
                        updateInfo.latestVersion,
                        Icons.arrow_circle_up,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                // ← Hint: تحذير إذا كان إجباري
                if (updateInfo.isMandatory) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'هذا التحديث مطلوب للاستمرار'
                                : 'This update is required to continue',
                            style: const TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // ← Hint: زر "لاحقاً" (فقط إذا لم يكن إجباري)
              if (!updateInfo.isMandatory)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(isArabic ? 'لاحقاً' : 'Later'),
                ),

              // ← Hint: زر "تحديث الآن"
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _openUpdateUrl(updateInfo.downloadUrl);
                },
                icon: const Icon(Icons.download),
                label: Text(isArabic ? 'تحديث الآن' : 'Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ← Hint: بناء سطر معلومات الإصدار
  // ==========================================================================
  Widget _buildVersionRow(String label, String version, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          version,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ← Hint: فتح رابط التحديث
  // ==========================================================================
  /// 🔗 فتح رابط التحديث
  ///
  /// ← Hint: يفتح المتجر (Play Store أو App Store)
  /// ← Hint: إذا لم يكن هناك رابط → لا يفعل شيء
  void _openUpdateUrl(String? url) {
    if (url == null || url.isEmpty) {
      debugPrint('⚠️ [UpdateChecker] لا يوجد رابط تحديث');
      return;
    }

    try {
      // ← Hint: TODO: استخدام url_launcher لفتح الرابط
      // ← Hint: سيتم تفعيله بعد إضافة المكتبة
      debugPrint('🔗 [UpdateChecker] فتح رابط التحديث: $url');
      // await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('❌ [UpdateChecker] خطأ في فتح رابط التحديث: $e');
    }
  }

  // ==========================================================================
  // ← Hint: مسح الـ Cache (لإعادة الفحص)
  // ==========================================================================
  /// 🔄 مسح الـ Cache وإعادة الفحص
  ///
  /// ← Hint: استخدمها إذا أردت فحص التحديثات مرة أخرى
  void clearCache() {
    _cachedUpdateInfo = null;
    _hasChecked = false;
    debugPrint('🗑️ [UpdateChecker] تم مسح الـ Cache');
  }
}
