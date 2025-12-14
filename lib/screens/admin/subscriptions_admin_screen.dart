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
            const PopupMenuItem(value: 'suspend', child: Text('إيقاف')),
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
      case 'delete':
        _confirmDeleteSubscription(doc);
        break;
    }
  }

  /// حوار إنشاء اشتراك جديد
  void _showCreateSubscriptionDialog() {
    // TODO: إضافة نموذج إنشاء اشتراك
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء اشتراك جديد'),
        content: const Text('قريباً...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// حوار تعديل اشتراك
  void _showEditSubscriptionDialog(DocumentSnapshot doc) {
    // TODO: إضافة نموذج تعديل
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاشتراك'),
        content: const Text('قريباً...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
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
  void _confirmSuspendSubscription(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إيقاف الاشتراك'),
        content: const Text('هل أنت متأكد من إيقاف هذا الاشتراك؟'),
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
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('إيقاف'),
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