# 🎛️ دليل إعداد Firebase Remote Config

## 📋 المحتويات
- [ما هو Remote Config؟](#ما-هو-remote-config)
- [الإعداد الأولي](#الإعداد-الأولي)
- [إضافة Flags التحكم](#إضافة-flags-التحكم)
- [الاستخدام في التطبيق](#الاستخدام-في-التطبيق)
- [أمثلة عملية](#أمثلة-عملية)

---

## ما هو Remote Config؟

Firebase Remote Config يسمح لك بـ:
- ✅ تغيير سلوك التطبيق **بدون نشر تحديث جديد**
- ✅ التحكم في المميزات عن بُعد
- ✅ اختبار A/B testing
- ✅ إنشاء Feature Flags للتحكم في المميزات

### حالة الاستخدام في مشروعنا:
```
Flag: auto_activate_trial
الغرض: التحكم في التفعيل التلقائي للاشتراكات التجريبية

- true → تفعيل تلقائي عند التسجيل (مفيد للتطوير والاختبار)
- false → تفعيل يدوي من المطور (مفيد للإنتاج)
```

---

## الإعداد الأولي

### الخطوة 1: فتح Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. من القائمة الجانبية، اختر **Remote Config**

### الخطوة 2: إنشاء أول Parameter

انقر على **"Add parameter"** أو **"إضافة معامل"**

---

## إضافة Flags التحكم

### Flag 1: `auto_activate_trial` ⭐ (الأهم)

#### الإعدادات:
```
Parameter key: auto_activate_trial
Description: التحكم في التفعيل التلقائي للاشتراكات التجريبية (14 يوم)
Data type: Boolean
Default value: false
```

#### خطوات الإضافة:

1. **Parameter key**: `auto_activate_trial`

2. **Description** (اختياري):
   ```
   التحكم في التفعيل التلقائي للاشتراكات التجريبية.
   - true: تفعيل تلقائي عند التسجيل (مفيد للتطوير)
   - false: تفعيل يدوي من المطور (مفيد للإنتاج)
   ```

3. **Data type**: اختر **Boolean**

4. **Default value**: اختر **false**
   - ⚠️ **مهم**: ابدأ بـ `false` للأمان
   - يمكن تغييره لـ `true` عند الحاجة

5. انقر **Save** ثم **Publish changes**

#### الشرح التفصيلي:

| القيمة | الوصف | متى تُستخدم |
|-------|-------|-------------|
| `true` | تفعيل تلقائي | مرحلة التطوير/الاختبار |
| `false` | تفعيل يدوي | مرحلة الإنتاج |

---

### Flag 2: `trial_period_days` (اختياري)

للتحكم في مدة الفترة التجريبية:

```
Parameter key: trial_period_days
Description: عدد أيام الفترة التجريبية
Data type: Number
Default value: 14
```

**الفائدة**: يمكنك تغيير مدة التجربة (14 يوم → 7 أيام مثلاً) بدون تحديث التطبيق

---

### Flag 3: `max_trial_devices` (اختياري)

للتحكم في عدد الأجهزة المسموحة في الفترة التجريبية:

```
Parameter key: max_trial_devices
Description: عدد الأجهزة المسموحة في الاشتراك التجريبي
Data type: Number
Default value: 3
```

---

### Flag 4: `app_is_active` (مهم للأمان)

للتحكم في تشغيل/إيقاف التطبيق:

```
Parameter key: app_is_active
Description: حالة التطبيق (تشغيل/إيقاف/صيانة)
Data type: JSON
Default value:
{
  "isActive": true,
  "reason": "",
  "message": "التطبيق يعمل بشكل طبيعي"
}
```

**أمثلة**:

وضع الصيانة:
```json
{
  "isActive": false,
  "reason": "maintenance",
  "message": "التطبيق في وضع الصيانة. سيعود قريباً."
}
```

إيقاف كامل:
```json
{
  "isActive": false,
  "reason": "suspended",
  "message": "التطبيق متوقف مؤقتاً. يرجى التواصل مع الدعم."
}
```

---

### Flag 5: `min_app_version` (للتحديثات الإجبارية)

```
Parameter key: min_app_version
Description: الحد الأدنى لإصدار التطبيق المطلوب
Data type: String
Default value: "1.0.0"
```

**الاستخدام**:
```dart
final currentVersion = "1.2.0";
final minVersion = FirebaseService.instance.remoteConfig.getString('min_app_version');

if (isVersionLower(currentVersion, minVersion)) {
  // اطلب من المستخدم التحديث
  showUpdateDialog();
}
```

---

## الإعدادات المتقدمة

### Conditions (الشروط)

يمكنك إنشاء قيم مختلفة حسب الشروط:

#### مثال: تفعيل تلقائي لمستخدمي iOS فقط

1. انقر **Add condition**
2. اسم الشرط: `iOS Users`
3. Rule: `Platform/OS matches regular expression ios`
4. في `auto_activate_trial`:
   - Default value: `false`
   - iOS Users condition: `true`

#### مثال: تفعيل تلقائي لنسخة معينة

1. Condition: `App version is 1.0.0`
2. في `auto_activate_trial`:
   - Version 1.0.0: `true`
   - Default: `false`

---

## نشر التغييرات

### ⚠️ مهم جداً:

بعد إضافة/تعديل أي Parameter:
1. انقر **Review** (مراجعة)
2. تأكد من الإعدادات
3. انقر **Publish changes** (نشر التغييرات)

**ملاحظة**: التغييرات لن تظهر في التطبيق حتى تنشرها!

---

## الاستخدام في التطبيق

### 1. قراءة Flag في Flutter

```dart
// الطريقة المستخدمة في register_screen.dart
final autoActivate = FirebaseService.instance.remoteConfig
    .getBool('auto_activate_trial');

if (autoActivate) {
  // تفعيل تلقائي
  await _createTrialSubscription(...);
}
```

### 2. قراءة Number

```dart
final trialDays = FirebaseService.instance.remoteConfig
    .getInt('trial_period_days');

final endDate = now.add(Duration(days: trialDays)); // مرن!
```

### 3. قراءة JSON

```dart
final appStatusJson = FirebaseService.instance.remoteConfig
    .getString('app_is_active');

final appStatus = jsonDecode(appStatusJson);

if (appStatus['isActive'] == false) {
  showMaintenanceDialog(appStatus['message']);
}
```

---

## التحديث والتحكم

### التحديث من Firebase Console

#### السيناريو 1: تفعيل التفعيل التلقائي أثناء التطوير

1. افتح Remote Config
2. ابحث عن `auto_activate_trial`
3. غيّر القيمة من `false` إلى `true`
4. انقر **Publish changes**

**النتيجة**: كل تسجيل جديد الآن سيُفعّل تلقائياً ✅

#### السيناريو 2: إيقاف التفعيل التلقائي في الإنتاج

1. افتح Remote Config
2. ابحث عن `auto_activate_trial`
3. غيّر القيمة من `true` إلى `false`
4. انقر **Publish changes**

**النتيجة**: التفعيل الآن يدوي فقط ✅

### التحديث عبر Firebase CLI (للمطورين)

```bash
# عرض الإعدادات الحالية
firebase remoteconfig:get

# تحديث من ملف JSON
firebase remoteconfig:publish config.json
```

---

## أمثلة عملية

### مثال 1: اختبار التطبيق مع تفعيل تلقائي

```
الوضع: أنت تختبر التطبيق وتحتاج إنشاء حسابات اختبارية بسرعة

الحل:
1. Remote Config → auto_activate_trial = true
2. Publish changes
3. سجل حسابات جديدة → ستُفعّل تلقائياً ✅
```

### مثال 2: الإطلاق للمستخدمين الحقيقيين

```
الوضع: جاهز لإطلاق التطبيق للمستخدمين

الحل:
1. Remote Config → auto_activate_trial = false
2. Publish changes
3. المستخدمون الجدد لن يُفعّلوا تلقائياً
4. أنت تفعّل يدوياً بعد التحقق من الدفع
```

### مثال 3: عرض خاص - تجربة مجانية 30 يوم

```
الوضع: عرض خاص لمدة محدودة

الحل:
1. Remote Config → trial_period_days = 30
2. Remote Config → auto_activate_trial = true
3. Publish changes
4. أعلن عن العرض 🎉
5. بعد انتهاء العرض:
   - trial_period_days = 14
   - auto_activate_trial = false
   - Publish changes
```

---

## مراقبة الاستخدام

### عرض إحصائيات Remote Config

1. Firebase Console → Remote Config
2. انقر على **Analytics** أو **التحليلات**
3. ستجد:
   - عدد مرات fetch
   - القيم الأكثر استخداماً
   - الأجهزة التي حصلت على القيم

### التحقق من آخر تحديث

```dart
final lastFetch = await FirebaseService.instance.getLastFetchTime();
debugPrint('آخر تحديث: $lastFetch');
```

---

## Best Practices (أفضل الممارسات)

### 1. قيم افتراضية آمنة
```dart
// ✅ جيد: قيمة افتراضية آمنة
final autoActivate = remoteConfig.getBool('auto_activate_trial') ?? false;

// ❌ سيء: لا توجد قيمة افتراضية
final autoActivate = remoteConfig.getBool('auto_activate_trial');
```

### 2. Caching ذكي
```dart
// في FirebaseService - تحديث كل 12 ساعة فقط
await remoteConfig.fetch();
await remoteConfig.activate();
```

### 3. Fallback عند الفشل
```dart
try {
  final autoActivate = remoteConfig.getBool('auto_activate_trial');
} catch (e) {
  // Fallback: قيمة افتراضية محلية
  final autoActivate = false;
}
```

### 4. اختبار محلي أولاً
```dart
// في الـ Development، استخدم قيم محلية للاختبار
final isDebugMode = kDebugMode;

final autoActivate = isDebugMode
    ? true // قيمة محلية للاختبار
    : remoteConfig.getBool('auto_activate_trial'); // قيمة حقيقية
```

---

## حل المشاكل الشائعة

### المشكلة 1: التطبيق لا يرى التغييرات الجديدة

**الحلول**:
1. تأكد من نشر التغييرات (Publish changes)
2. تأكد من fetch interval (الحد الأدنى 12 ساعة في الإنتاج)
3. استخدم force fetch للاختبار:
   ```dart
   await FirebaseService.instance.forceRefreshConfig();
   ```

### المشكلة 2: القيمة دائماً `false` حتى بعد التغيير

**الأسباب المحتملة**:
1. لم تنشر التغييرات (Publish)
2. التطبيق يستخدم Cache قديم
3. الـ Default value في الكود لم يُحدّث

**الحل**:
```dart
// امسح الـ Cache وأعد التحميل
await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: Duration(seconds: 10),
  minimumFetchInterval: Duration.zero, // للاختبار فقط!
));
await remoteConfig.fetchAndActivate();
```

### المشكلة 3: "Fetch throttled"

**السبب**: كثرة طلبات fetch (الحد: 5 طلبات/ساعة)

**الحل**:
```dart
// استخدم cache أطول في الإنتاج
final settings = RemoteConfigSettings(
  fetchTimeout: Duration(seconds: 10),
  minimumFetchInterval: Duration(hours: 12), // تحديث كل 12 ساعة
);
```

---

## الخلاصة

### الـ Flags الأساسية للمشروع:

| Flag | Type | Default | الغرض |
|------|------|---------|-------|
| `auto_activate_trial` | Boolean | `false` | التحكم في التفعيل التلقائي |
| `trial_period_days` | Number | `14` | مدة الفترة التجريبية |
| `app_is_active` | JSON | `{"isActive": true}` | حالة التطبيق |
| `min_app_version` | String | `"1.0.0"` | الحد الأدنى للإصدار |

### الخطوات السريعة:

1. ✅ افتح Firebase Console → Remote Config
2. ✅ أضف `auto_activate_trial` (Boolean, false)
3. ✅ Publish changes
4. ✅ في التطوير: غيّر لـ `true`
5. ✅ في الإنتاج: أرجع لـ `false`

---

**ملاحظة نهائية**: Remote Config يعطيك مرونة كبيرة بدون تحديثات، استخدمه بحكمة! 🎯
