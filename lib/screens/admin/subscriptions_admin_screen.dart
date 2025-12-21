// lib/screens/admin/subscriptions_admin_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_button.dart';
import 'activation_code_generator_screen.dart'; // 🆕 مولد الأكواد

/// ============================================================================
/// لوحة تحكم الاشتراكات (للمطور/المدير)
/// ============================================================================
/// 
/// ← Hint: الميزات:
/// - 📊 عرض جميع الاشتراكات من Firestore
/// - 🔍 البحث والفلترة
/// - ✏️ تعديل الاشتراكات
/// - ❌ حذف/تعليق الاشتراكات
/// - 🎫 إنشاء أكواد تفعيل
/// - 📈 إحصائيات
/// 
/// ============================================================================
class SubscriptionsAdminScreen extends StatefulWidget {
  const SubscriptionsAdminScreen({super.key});

  @override
  State<SubscriptionsAdminScreen> createState() => 
      _SubscriptionsAdminScreenState();
}

class _SubscriptionsAdminScreenState extends State<SubscriptionsAdminScreen> {

  // ==========================================================================
  // المتغيرات
  // ==========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, expired, suspended

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title:  Text(l10n.subscriptionmanagement),
        actions: [
          // زر إنشاء كود تفعيل
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'إنشاء كود تفعيل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivationCodeGeneratorScreen(),
                ),
              );
            },
          ),
          
          // زر تحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // شريط البحث والفلترة
          // ═══════════════════════════════════════════════════════════
          _buildSearchAndFilter(isDark),

          // ═══════════════════════════════════════════════════════════
          // الإحصائيات السريعة
          // ═══════════════════════════════════════════════════════════
          _buildQuickStats(),

          // ═══════════════════════════════════════════════════════════
          // قائمة الاشتراكات
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: _buildSubscriptionsList(),
          ),
        ],
      ),
      
      // ═══════════════════════════════════════════════════════════
      // زر عائم: إنشاء اشتراك جديد
      // ═══════════════════════════════════════════════════════════
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSubscriptionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('اشتراك جديد'),
      ),
    );
  }

  // ==========================================================================
  // UI Components
  // ==========================================================================

  /// شريط البحث والفلترة
  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      padding: AppConstants.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث بالإيميل...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: AppConstants.borderRadiusMd,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // الفلاتر
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all'),
                const SizedBox(width: AppConstants.spacingSm),
                _buildFilterChip('نشط', 'active'),
                const SizedBox(width: AppConstants.spacingSm),
                _buildFilterChip('منتهي', 'expired'),
                const SizedBox(width: AppConstants.spacingSm),
                _buildFilterChip('موقوف', 'suspended'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: AppColors.primaryLight.withOpacity(0.2),
      checkmarkColor: AppColors.primaryLight,
    );
  }

  /// الإحصائيات السريعة
  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('subscriptions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        
        final total = docs.length;
        final active = docs.where((doc) => 
            doc.get('isActive') == true && 
            (doc.get('endDate') as Timestamp?)?.toDate().isAfter(DateTime.now()) == true
        ).length;
        final expired = docs.where((doc) => 
            (doc.get('endDate') as Timestamp?)?.toDate().isBefore(DateTime.now()) == true
        ).length;
        final trial = docs.where((doc) => doc.get('plan') == 'trial').length;

        return Container(
          padding: AppConstants.paddingMd,
          child: Row(
            children: [
              _buildStatCard('المجموع', total.toString(), AppColors.info),
              const SizedBox(width: AppConstants.spacingSm),
              _buildStatCard('نشط', active.toString(), AppColors.success),
              const SizedBox(width: AppConstants.spacingSm),
              _buildStatCard('منتهي', expired.toString(), AppColors.error),
              const SizedBox(width: AppConstants.spacingSm),
              _buildStatCard('تجريبي', trial.toString(), AppColors.warning),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: AppConstants.paddingSm,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppConstants.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قائمة الاشتراكات
  Widget _buildSubscriptionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('لا توجد اشتراكات'),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: AppConstants.paddingMd,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildSubscriptionCard(doc);
          },
        );
      },
    );
  }

  /// بطاقة اشتراك
  Widget _buildSubscriptionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final email = data['email'] as String? ?? 'N/A';
    final plan = data['plan'] as String? ?? 'unknown';
    final status = data['status'] as String? ?? 'inactive';
    final isActive = data['isActive'] as bool? ?? false;
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final displayName = data['displayName'] as String? ?? '';

    // حساب الأيام المتبقية
    int? daysRemaining;
    if (endDate != null) {
      daysRemaining = endDate.difference(DateTime.now()).inDays;
    }

    // تحديد اللون
    Color statusColor;
    if (!isActive || (daysRemaining != null && daysRemaining <= 0)) {
      statusColor = AppColors.error;
    } else if (daysRemaining != null && daysRemaining <= 3) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getPlanIcon(plan),
            color: statusColor,
          ),
        ),
        title: Text(
          displayName.isNotEmpty ? displayName : email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayName.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusSm,
                  ),
                  child: Text(
                    _getPlanDisplayName(plan),
                    style: TextStyle(fontSize: 10, color: statusColor),
                  ),
                ),
                const SizedBox(width: 6),
                if (daysRemaining != null && daysRemaining > 0)
                  Text(
                    '$daysRemaining يوم',
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
              ],
            ),
            if (endDate != null)
              Text(
                'ينتهي: ${_formatDate(endDate)}',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, doc),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'extend', child: Text('تمديد')),

            // ═══════════════════════════════════════════════════════════════
            // ← Hint: زر إيقاف/تفعيل ديناميكي (يتغير حسب حالة الاشتراك)
            // ═══════════════════════════════════════════════════════════════
            // ← Hint: إذا كان status = 'suspended' → يعرض "تفعيل"
            // ← Hint: إذا كان status = 'active' → يعرض "إيقاف"
            // ← Hint: القيمة المرسلة: 'resume' أو 'suspend'
            PopupMenuItem(
              value: status == 'suspended' ? 'resume' : 'suspend',
              child: Row(
                children: [
                  Icon(
                    status == 'suspended' ? Icons.play_arrow : Icons.pause,
                    size: 18,
                    color: status == 'suspended' ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(status == 'suspended' ? 'تفعيل' : 'إيقاف'),
                ],
              ),
            ),

            const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  /// معالجة اختيار القائمة
  ///
  /// ← Hint: يعالج جميع إجراءات القائمة المنبثقة
  /// ← Hint: الإجراءات المدعومة:
  ///   - edit: تعديل الاشتراك
  ///   - extend: تمديد الاشتراك
  ///   - suspend: إيقاف الاشتراك
  ///   - resume: تفعيل الاشتراك الموقوف (🆕)
  ///   - delete: حذف الاشتراك
  void _handleMenuAction(String action, DocumentSnapshot doc) {
    switch (action) {
      case 'edit':
        _showEditSubscriptionDialog(doc);
        break;
      case 'extend':
        _showExtendSubscriptionDialog(doc);
        break;
      case 'suspend':
        _confirmSuspendSubscription(doc);
        break;
      case 'resume': // ← Hint: 🆕 إجراء جديد لتفعيل الاشتراك الموقوف
        _confirmResumeSubscription(doc);
        break;
      case 'delete':
        _confirmDeleteSubscription(doc);
        break;
    }
  }

  // ==========================================================================
  // ← Hint: 🆕 دالة محدّثة - إنشاء اشتراك جديد
  // ==========================================================================

  /// حوار إنشاء اشتراك جديد
  ///
  /// ← Hint: يسمح بإنشاء اشتراك جديد من لوحة التحكم مباشرة
  /// ← Hint: الحقول المطلوبة (*):
  ///   - email*: الإيميل (يجب أن يكون فريد)
  ///   - plan*: نوع الخطة
  ///   - days*: المدة بالأيام
  ///   - maxDevices*: عدد الأجهزة
  /// ← Hint: الحقول الاختيارية:
  ///   - displayName: الاسم
  ///   - notes: ملاحظات
  /// ← Hint: يتم التحقق من:
  ///   1. صحة الإيميل (يحتوي على @)
  ///   2. عدم وجود اشتراك بنفس الإيميل
  ///   3. المدة أكبر من صفر
  void _showCreateSubscriptionDialog() {
    // ═══════════════════════════════════════════════════════════════════
    // ← Hint: Controllers للحقول
    // ═══════════════════════════════════════════════════════════════════
    final emailController = TextEditingController();
    final displayNameController = TextEditingController();
    final notesController = TextEditingController();
    final daysController = TextEditingController(text: '30');

    String selectedPlan = 'premium';
    int maxDevices = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.primaryLight),
              SizedBox(width: 8),
              Text('إنشاء اشتراك جديد'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ═════════════════════════════════════════════════════════
                  // معلومات توضيحية
                  // ═════════════════════════════════════════════════════════
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.info),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم إنشاء اشتراك جديد في Firestore',
                            style: TextStyle(fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ═════════════════════════════════════════════════════════
                  // الإيميل (مطلوب)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'الإيميل *',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // الاسم (اختياري)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم (اختياري)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // نوع الخطة
                  // ═════════════════════════════════════════════════════════
                  // ← Hint: تحديث القيم الافتراضية عند تغيير الخطة
                  DropdownButtonFormField<String>(
                    value: selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'نوع الخطة *',
                      prefixIcon: Icon(Icons.card_membership),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'trial', child: Text('🎯 تجريبي (14 يوم)')),
                      DropdownMenuItem(value: 'premium', child: Text('⭐ مميز')),
                      DropdownMenuItem(value: 'professional', child: Text('💼 احترافي')),
                      DropdownMenuItem(value: 'lifetime', child: Text('♾️ دائم')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPlan = value!;

                        // ← Hint: تحديث القيم الافتراضية حسب نوع الخطة
                        if (selectedPlan == 'trial') {
                          daysController.text = '14';
                          maxDevices = 3;
                        } else if (selectedPlan == 'lifetime') {
                          daysController.text = '36500'; // 100 سنة
                          maxDevices = 999;
                        } else if (selectedPlan == 'professional') {
                          daysController.text = '30';
                          maxDevices = 10;
                        } else {
                          daysController.text = '30';
                          maxDevices = 3;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // المدة (بالأيام)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المدة (بالأيام) *',
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixText: 'يوم',
                      border: OutlineInputBorder(),
                      helperText: 'مثال: 30 = شهر، 365 = سنة',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // عدد الأجهزة
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأجهزة المسموحة *',
                      prefixIcon: Icon(Icons.devices),
                      border: OutlineInputBorder(),
                      helperText: '0 = غير محدود',
                    ),
                    controller: TextEditingController(text: maxDevices.toString()),
                    onChanged: (value) {
                      maxDevices = int.tryParse(value) ?? 3;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // ملاحظات (اختياري)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                // ═══════════════════════════════════════════════════════════
                // ← Hint: التحقق من البيانات
                // ═══════════════════════════════════════════════════════════
                final email = emailController.text.trim();

                // ← Hint: التحقق من صحة الإيميل
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ الرجاء إدخال إيميل صحيح'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // ← Hint: التحقق من المدة
                final days = int.tryParse(daysController.text) ?? 0;
                if (days <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ المدة يجب أن تكون أكبر من صفر'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // ═══════════════════════════════════════════════════════════
                // ← Hint: التحقق من عدم وجود اشتراك بنفس الإيميل
                // ═══════════════════════════════════════════════════════════
                final existingDoc = await _firestore
                    .collection('subscriptions')
                    .doc(email)
                    .get();

                if (existingDoc.exists) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ يوجد اشتراك بهذا الإيميل مسبقاً!\n$email'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  return;
                }

                // ═══════════════════════════════════════════════════════════
                // ← Hint: إنشاء الاشتراك في Firestore
                // ═══════════════════════════════════════════════════════════
                final now = DateTime.now();
                final endDate = now.add(Duration(days: days));

                await _firestore.collection('subscriptions').doc(email).set({
                  'email': email,
                  'displayName': displayNameController.text.trim(),
                  'plan': selectedPlan,
                  'status': 'active',
                  'isActive': true,
                  'startDate': Timestamp.fromDate(now),
                  'endDate': Timestamp.fromDate(endDate),
                  'maxDevices': maxDevices,
                  'currentDevices': [], // ← Hint: قائمة فارغة في البداية
                  'notes': notesController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'createdBy': 'admin', // ← Hint: يمكن وضع email الأدمن هنا

                  // ← Hint: الميزات حسب نوع الخطة
                  'features': {
                    'multiUser': selectedPlan == 'professional' || selectedPlan == 'premium',
                    'backup': true,
                    'reports': true,
                    'accounting': selectedPlan != 'trial', // ← Hint: المحاسبة غير متاحة للتجريبي
                  },
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✅ تم إنشاء اشتراك جديد بنجاح!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('الإيميل: $email'),
                          Text('الخطة: ${_getPlanDisplayName(selectedPlan)}'),
                          Text('المدة: $days يوم'),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 6),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('إنشاء الاشتراك'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ← Hint: 🆕 دالة محدّثة - تعديل الاشتراك
  // ==========================================================================

  /// حوار تعديل اشتراك
  ///
  /// ← Hint: يسمح بتعديل معلومات الاشتراك الأساسية
  /// ← Hint: الحقول القابلة للتعديل:
  ///   - displayName: الاسم (اختياري)
  ///   - plan: نوع الخطة (trial, premium, professional, lifetime)
  ///   - maxDevices: عدد الأجهزة المسموحة
  ///   - notes: ملاحظات (اختياري)
  /// ← Hint: الحقول غير القابلة للتعديل:
  ///   - email: الإيميل (معرّف رئيسي - read-only)
  ///   - endDate: تاريخ الانتهاء (استخدم "تمديد" لتغييره)
  void _showEditSubscriptionDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ═══════════════════════════════════════════════════════════════════
    // ← Hint: Controllers للحقول القابلة للتعديل
    // ═══════════════════════════════════════════════════════════════════
    final emailController = TextEditingController(text: data['email']);
    final displayNameController = TextEditingController(text: data['displayName'] ?? '');
    final notesController = TextEditingController(text: data['notes'] ?? '');

    String selectedPlan = data['plan'] ?? 'premium';
    int maxDevices = data['maxDevices'] ?? 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryLight),
              SizedBox(width: 8),
              Text('تعديل الاشتراك'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ═════════════════════════════════════════════════════════
                  // الإيميل (read-only)
                  // ═════════════════════════════════════════════════════════
                  // ← Hint: لا يمكن تعديل الإيميل لأنه معرّف الوثيقة في Firestore
                  TextField(
                    controller: emailController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'الإيميل',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // الاسم (اختياري)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم (اختياري)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // نوع الخطة
                  // ═════════════════════════════════════════════════════════
                  // ← Hint: تحديث القيم الافتراضية عند تغيير الخطة
                  DropdownButtonFormField<String>(
                    value: selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'نوع الخطة',
                      prefixIcon: Icon(Icons.card_membership),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'trial', child: Text('🎯 تجريبي')),
                      DropdownMenuItem(value: 'premium', child: Text('⭐ مميز')),
                      DropdownMenuItem(value: 'professional', child: Text('💼 احترافي')),
                      DropdownMenuItem(value: 'lifetime', child: Text('♾️ دائم')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedPlan = value!);
                    },
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // عدد الأجهزة
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأجهزة المسموحة',
                      prefixIcon: Icon(Icons.devices),
                      border: OutlineInputBorder(),
                      helperText: '0 = غير محدود',
                    ),
                    controller: TextEditingController(text: maxDevices.toString()),
                    onChanged: (value) {
                      maxDevices = int.tryParse(value) ?? 3;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ═════════════════════════════════════════════════════════
                  // ملاحظات (اختياري)
                  // ═════════════════════════════════════════════════════════
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                // ═══════════════════════════════════════════════════════════
                // ← Hint: تحديث البيانات في Firestore
                // ═══════════════════════════════════════════════════════════
                await doc.reference.update({
                  'displayName': displayNameController.text.trim(),
                  'plan': selectedPlan,
                  'maxDevices': maxDevices,
                  'notes': notesController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم تحديث الاشتراك بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
              ),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  /// حوار تمديد اشتراك
  void _showExtendSubscriptionDialog(DocumentSnapshot doc) {
    final daysController = TextEditingController(text: '30');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمديد الاشتراك'),
        content: TextField(
          controller: daysController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'عدد الأيام',
            suffixText: 'يوم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final days = int.tryParse(daysController.text) ?? 0;
              if (days > 0) {
                await _extendSubscription(doc, days);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('تمديد'),
          ),
        ],
      ),
    );
  }

  /// تمديد الاشتراك
  Future<void> _extendSubscription(DocumentSnapshot doc, int days) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final currentEndDate = (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final newEndDate = currentEndDate.add(Duration(days: days));

      await doc.reference.update({
        'endDate': Timestamp.fromDate(newEndDate),
        'status': 'active',
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تمديد الاشتراك $days يوم')),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تمديد الاشتراك: $e');
    }
  }

  /// تأكيد إيقاف اشتراك
  ///
  /// ← Hint: يوقف الاشتراك مؤقتاً (يمكن إعادة تفعيله لاحقاً)
  /// ← Hint: التحديثات في Firestore:
  ///   - status → 'suspended'
  ///   - isActive → false
  ///   - suspensionReason → سبب الإيقاف
  ///   - suspendedAt → timestamp (🆕 للتوثيق)
  void _confirmSuspendSubscription(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle, color: AppColors.warning),
            SizedBox(width: 8),
            Text('إيقاف الاشتراك'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إيقاف هذا الاشتراك؟\n\n'
          'ملاحظة: يمكنك تفعيله مرة أخرى في أي وقت.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'status': 'suspended',
                'isActive': false,
                'suspensionReason': 'تم الإيقاف من لوحة التحكم',
                'suspendedAt': FieldValue.serverTimestamp(), // ← Hint: 🆕 توثيق وقت الإيقاف
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إيقاف الاشتراك بنجاح'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ← Hint: 🆕 دالة جديدة - تفعيل الاشتراك الموقوف
  // ==========================================================================

  /// تأكيد تفعيل اشتراك موقوف
  ///
  /// ← Hint: يعيد تفعيل اشتراك تم إيقافه مسبقاً
  /// ← Hint: الشروط:
  ///   1. يجب أن يكون status = 'suspended'
  ///   2. يجب أن يكون endDate لم ينته بعد
  /// ← Hint: إذا كان التاريخ منتهي → يطلب من Admin التمديد أولاً
  /// ← Hint: التحديثات في Firestore:
  ///   - status → 'active'
  ///   - isActive → true
  ///   - suspensionReason → null (مسح السبب)
  ///   - resumedAt → timestamp (للتوثيق)
  void _confirmResumeSubscription(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('تفعيل الاشتراك'),
          ],
        ),
        content: const Text(
          'هل تريد تفعيل هذا الاشتراك؟\n\n'
          'سيتمكن المستخدم من استخدام التطبيق مباشرة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              // ═══════════════════════════════════════════════════════════
              // ← Hint: التحقق من تاريخ الانتهاء قبل التفعيل
              // ═══════════════════════════════════════════════════════════
              final data = doc.data() as Map<String, dynamic>;
              final endDate = (data['endDate'] as Timestamp?)?.toDate();
              final now = DateTime.now();

              // ← Hint: إذا كان التاريخ منتهي → لا يمكن التفعيل
              if (endDate != null && endDate.isBefore(now)) {
                Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '❌ لا يمكن تفعيل اشتراك منتهي!\n'
                        'قم بتمديد الاشتراك أولاً',
                      ),
                      backgroundColor: AppColors.error,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
                return;
              }

              // ═══════════════════════════════════════════════════════════
              // ← Hint: تفعيل الاشتراك في Firestore
              // ═══════════════════════════════════════════════════════════
              await doc.reference.update({
                'status': 'active',
                'isActive': true,
                'suspensionReason': null, // ← Hint: مسح سبب الإيقاف
                'resumedAt': FieldValue.serverTimestamp(), // ← Hint: توثيق وقت التفعيل
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم تفعيل الاشتراك بنجاح'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
  }

  /// تأكيد حذف اشتراك
  void _confirmDeleteSubscription(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الاشتراك'),
        content: const Text('هل أنت متأكد من حذف هذا الاشتراك؟ لا يمكن التراجع!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  /// الحصول على الاشتراكات المفلترة
  Stream<QuerySnapshot> _getFilteredSubscriptions() {
    Query query = _firestore.collection('subscriptions');

    // تطبيق الفلتر
    switch (_filterStatus) {
      case 'active':
        query = query.where('isActive', isEqualTo: true);
        break;
      case 'expired':
        query = query.where('isActive', isEqualTo: false);
        break;
      case 'suspended':
        query = query.where('status', isEqualTo: 'suspended');
        break;
    }

    return query.snapshots();
  }

  IconData _getPlanIcon(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial': return Icons.access_time;
      case 'premium': return Icons.workspace_premium;
      case 'professional': return Icons.business_center;
      case 'lifetime': return Icons.all_inclusive;
      default: return Icons.card_membership;
    }
  }

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial': return 'تجريبي';
      case 'premium': return 'مميز';
      case 'professional': return 'احترافي';
      case 'lifetime': return 'دائم';
      default: return 'غير محدد';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}