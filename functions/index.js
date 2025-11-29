// ===========================================================================
// ⚠️ Cloud Functions for Firebase - Auto Trial Subscription
// ===========================================================================
// 📌 ملاحظة مهمة:
//    - يتطلب Blaze Plan (الخطة المدفوعة) لتشغيل Cloud Functions
//    - حالياً التطبيق يستخدم Flutter-based solution (تعمل على Spark Plan)
//    - هذا الملف جاهز للنشر عند الترقية لـ Blaze Plan
// ===========================================================================

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Hint: تهيئة Firebase Admin SDK
admin.initializeApp();

// ===========================================================================
// 🔧 Cloud Function: إنشاء اشتراك تجريبي تلقائي عند التسجيل
// ===========================================================================
/**
 * Hint: تُشغّل تلقائياً عند إنشاء مستخدم جديد في Firebase Authentication
 *
 * المزايا مقارنة بـ Flutter solution:
 * - ✅ أكثر أماناً (لا يمكن للمستخدم التلاعب بها)
 * - ✅ مركزية (كل المنطق في مكان واحد)
 * - ✅ لا تحتاج تحديث التطبيق لتغيير المنطق
 *
 * العيوب:
 * - ❌ تتطلب Blaze Plan
 * - ❌ تكلفة إضافية (صغيرة جداً للاستخدام المتوسط)
 */
exports.createTrialSubscription = functions.auth.user().onCreate(async (user) => {
  try {
    const firestore = admin.firestore();
    const remoteConfig = admin.remoteConfig();

    // 1️⃣ Hint: التحقق من flag التفعيل التلقائي في Remote Config
    const template = await remoteConfig.getTemplate();
    const autoActivate = template.parameters['auto_activate_trial']?.defaultValue?.value === 'true';

    if (!autoActivate) {
      console.log(`🚫 التفعيل التلقائي معطل - تخطي المستخدم: ${user.email}`);
      return null;
    }

    console.log(`🚀 إنشاء اشتراك تجريبي تلقائياً للمستخدم: ${user.email}`);

    // 2️⃣ Hint: حساب تواريخ الاشتراك
    const now = admin.firestore.Timestamp.now();
    const startDate = now;
    const endDate = admin.firestore.Timestamp.fromDate(
      new Date(now.toDate().getTime() + 14 * 24 * 60 * 60 * 1000) // +14 يوم
    );

    // 3️⃣ Hint: بيانات الاشتراك التجريبي
    const subscriptionData = {
      email: user.email,
      displayName: user.displayName || 'Owner',

      // Hint: معلومات الخطة
      plan: 'trial',
      status: 'active',
      isActive: true,

      // Hint: التواريخ
      startDate: startDate,
      endDate: endDate,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),

      // Hint: إعدادات الأجهزة (Professional: 3 أجهزة)
      maxDevices: 3,
      currentDevices: [],

      // Hint: المميزات المتاحة في الفترة التجريبية
      features: {
        canCreateSubUsers: true,
        maxSubUsers: 10,
        canExportData: true,
        canUseAdvancedReports: true,
        supportPriority: 'standard',
      },

      // Hint: سجل الدفعات (فارغ للتجربة المجانية)
      paymentHistory: [
        {
          amount: 0,
          currency: 'USD',
          method: 'auto_trial_cloud_function',
          paidAt: now,
          receiptUrl: null,
        }
      ],

      notes: 'تفعيل تجريبي تلقائي (Cloud Function) - 14 يوم',

      // Hint: معلومات إضافية للتتبع
      createdBy: 'cloud_function',
      createdVia: 'firebase_auth_trigger',
      uid: user.uid,
    };

    // 4️⃣ Hint: إنشاء الاشتراك في Firestore
    await firestore.collection('subscriptions').doc(user.email).set(subscriptionData);

    console.log(`✅ تم إنشاء الاشتراك التجريبي بنجاح: ${user.email}`);

    // 5️⃣ Hint: (اختياري) إرسال إيميل ترحيبي
    // يمكن استخدام SendGrid أو Firebase Extensions
    // await sendWelcomeEmail(user.email, user.displayName);

    return {
      success: true,
      email: user.email,
      plan: 'trial',
      endDate: endDate.toDate().toISOString(),
    };

  } catch (error) {
    console.error('❌ خطأ في إنشاء الاشتراك التجريبي:', error);

    // Hint: لا نرفع exception حتى لا نفشل عملية التسجيل
    // بدلاً من ذلك، نسجل الخطأ ونتركه للتفعيل اليدوي
    return {
      success: false,
      error: error.message,
    };
  }
});

// ===========================================================================
// 🔧 Cloud Function: تنبيه قبل انتهاء الفترة التجريبية
// ===========================================================================
/**
 * Hint: تُشغّل يومياً للتحقق من الاشتراكات القريبة من الانتهاء
 */
exports.checkExpiringTrials = functions.pubsub
  .schedule('0 9 * * *') // Hint: كل يوم الساعة 9 صباحاً
  .timeZone('Asia/Riyadh')
  .onRun(async (context) => {
    try {
      const firestore = admin.firestore();
      const now = new Date();
      const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

      console.log('🔍 فحص الاشتراكات التجريبية القريبة من الانتهاء...');

      // Hint: البحث عن اشتراكات تنتهي خلال 3 أيام
      const expiringTrials = await firestore
        .collection('subscriptions')
        .where('plan', '==', 'trial')
        .where('status', '==', 'active')
        .where('endDate', '<=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .get();

      console.log(`📊 عدد الاشتراكات القريبة من الانتهاء: ${expiringTrials.size}`);

      // Hint: إرسال تنبيهات
      const notifications = expiringTrials.docs.map(async (doc) => {
        const data = doc.data();
        const daysLeft = Math.ceil(
          (data.endDate.toDate().getTime() - now.getTime()) / (24 * 60 * 60 * 1000)
        );

        console.log(`📧 إرسال تنبيه إلى: ${data.email} (${daysLeft} أيام متبقية)`);

        // Hint: يمكن إرسال إيميل أو إشعار push
        // await sendExpirationNotification(data.email, daysLeft);

        return { email: data.email, daysLeft };
      });

      const results = await Promise.all(notifications);

      console.log(`✅ تم إرسال ${results.length} تنبيه بنجاح`);

      return { count: results.length, notifications: results };
    } catch (error) {
      console.error('❌ خطأ في فحص الاشتراكات المنتهية:', error);
      throw error;
    }
  });

// ===========================================================================
// 🔧 Cloud Function: تعطيل الاشتراكات المنتهية
// ===========================================================================
/**
 * Hint: تُشغّل يومياً لتعطيل الاشتراكات التي انتهت
 */
exports.deactivateExpiredSubscriptions = functions.pubsub
  .schedule('0 0 * * *') // Hint: كل يوم منتصف الليل
  .timeZone('Asia/Riyadh')
  .onRun(async (context) => {
    try {
      const firestore = admin.firestore();
      const now = admin.firestore.Timestamp.now();

      console.log('🔍 فحص الاشتراكات المنتهية...');

      // Hint: البحث عن اشتراكات نشطة لكنها انتهت
      const expiredSubscriptions = await firestore
        .collection('subscriptions')
        .where('status', '==', 'active')
        .where('endDate', '<', now)
        .get();

      console.log(`📊 عدد الاشتراكات المنتهية: ${expiredSubscriptions.size}`);

      // Hint: تعطيل الاشتراكات
      const batch = firestore.batch();

      expiredSubscriptions.docs.forEach((doc) => {
        console.log(`❌ تعطيل اشتراك: ${doc.id}`);

        batch.update(doc.ref, {
          status: 'expired',
          isActive: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      console.log(`✅ تم تعطيل ${expiredSubscriptions.size} اشتراك`);

      return { count: expiredSubscriptions.size };
    } catch (error) {
      console.error('❌ خطأ في تعطيل الاشتراكات المنتهية:', error);
      throw error;
    }
  });
