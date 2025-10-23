// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../layouts/main_layout.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';

/// ===========================================================================
/// لوحة التحكم الرئيسية (Dashboard Screen)
/// ===========================================================================
/// الغرض:
/// - عرض إحصائيات سريعة عن النشاط التجاري
/// - إظهار أهم المنتجات والعملاء
/// - ملخص المبيعات والأرباح اليومية/الشهرية
/// - رسوم بيانية توضيحية (اختياري)
/// ===========================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  // ============= قاعدة البيانات =============
  final dbHelper = DatabaseHelper.instance;
  
  // ============= Futures لجلب البيانات =============
  late Future<List<Product>> _topProductsFuture;
  late Future<List<Customer>> _topCustomersFuture;
  late Future<Map<String, dynamic>> _statsMapFuture;

  // ============= متغيرات الحالة =============
  int _currentBottomNavIndex = 0;

  // ===========================================================================
  // التهيئة الأولية
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ===========================================================================
  // تحميل البيانات
  // ===========================================================================
  void _loadData() {
    _topProductsFuture = dbHelper.getTopSellingProducts();
    _topCustomersFuture = dbHelper.getTopCustomers();
    
    // TODO: استبدل هذا بدالة حقيقية من قاعدة البيانات
    _statsMapFuture = _fetchDashboardStats();
  }

  // ===========================================================================
  // جلب إحصائيات Dashboard (مؤقت - استبدله بدالة حقيقية)
  // ===========================================================================
  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    // Hint: هنا تضع دالة حقيقية تجلب الإحصائيات من قاعدة البيانات
    await Future.delayed(const Duration(milliseconds: 500)); // محاكاة تأخير الشبكة
    
    return {
      'todaySales': 1250000.0,      // مبيعات اليوم
      'todayProfit': 350000.0,      // أرباح اليوم
      'monthSales': 15000000.0,     // مبيعات الشهر
      'monthProfit': 4200000.0,     // أرباح الشهر
      'totalCustomers': 45,         // عدد العملاء
      'totalProducts': 230,         // عدد المنتجات
      'lowStockProducts': 12,       // منتجات منخفضة المخزون
      'pendingPayments': 2500000.0, // مدفوعات معلقة
    };
  }

  // ===========================================================================
  // إعادة تحميل البيانات
  // ===========================================================================
  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  // ===========================================================================
  // بناء واجهة المستخدم
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'لوحة التحكم',
      currentIndex: _currentBottomNavIndex,
      onBottomNavTap: (index) {
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: CustomScrollView(
          slivers: [
            // ============= الإحصائيات الرئيسية =============
            SliverToBoxAdapter(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: _buildMainStats(),
              ),
            ),

            // ============= المنتجات الأكثر مبيعاً =============
            SliverToBoxAdapter(
              child: _buildTopProductsSection(),
            ),

            // ============= العميل المميز =============
            SliverToBoxAdapter(
              child: _buildTopCustomerSection(),
            ),

            // ============= إحصائيات إضافية =============
            SliverToBoxAdapter(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: _buildAdditionalStats(),
              ),
            ),

            // ============= مسافة إضافية =============
            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXl),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // بناء الإحصائيات الرئيسية
  // ===========================================================================
  Widget _buildMainStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsMapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: LoadingState(message: 'جاري تحميل الإحصائيات...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'خطأ في تحميل البيانات',
            message: 'يرجى المحاولة مرة أخرى',
          );
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- عنوان القسم ---
            Text(
              'اليوم',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- إحصائيات اليوم ---
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'المبيعات',
                    value: _formatCurrency(stats['todaySales']),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: InfoCard(
                    title: 'الأرباح',
                    value: _formatCurrency(stats['todayProfit']),
                    icon: Icons.attach_money,
                    color: AppColors.profit,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // --- عنوان القسم ---
            Text(
              'هذا الشهر',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- إحصائيات الشهر ---
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'المبيعات',
                    value: _formatCurrency(stats['monthSales']),
                    icon: Icons.shopping_cart,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: InfoCard(
                    title: 'الأرباح',
                    value: _formatCurrency(stats['monthProfit']),
                    icon: Icons.trending_up,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // بناء قسم المنتجات الأكثر مبيعاً
  // ===========================================================================
  Widget _buildTopProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- عنوان القسم ---
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingLg,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
          ),
          child: Text(
            'الأكثر مبيعاً',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // --- قائمة المنتجات ---
        FutureBuilder<List<Product>>(
          future: _topProductsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: LoadingState(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: AppConstants.paddingMd,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'لا توجد مبيعات',
                  message: 'لا توجد بيانات كافية لعرض المنتجات الأكثر مبيعاً',
                ),
              );
            }

            final products = snapshot.data!;

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء بطاقة المنتج
  // ===========================================================================
 Widget _buildProductCard(Product product) {

   // صورة المنتج معطلة حاليا
   
  // final hasImage = product.imagePath != null && 
  //                product.imagePath!.isNotEmpty;
  // بدون صورة - فقط أيقونة
  return Container(
    width: 150,
    margin: const EdgeInsets.only(right: AppConstants.spacingMd),
    child: CustomCard(
      padding: AppConstants.paddingMd,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- أيقونة المنتج ---
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMd,
            ),
            child: Icon(
              Icons.inventory_2,
              size: 32,
              color: AppColors.primaryLight,
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingSm),
          
          // --- اسم المنتج ---
          Text(
            product.productName,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppConstants.spacingXs),
          
          // --- الكمية المتوفرة ---
          Text(
            'المتوفر: ${product.quantity}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: product.quantity < 10 
                ? AppColors.error 
                : AppColors.success,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ===========================================================================
  // بناء قسم العميل المميز
  // ===========================================================================
  Widget _buildTopCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- عنوان القسم ---
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingLg,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
          ),
          child: Text(
            'العميل المميز',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // --- بطاقة العميل ---
        FutureBuilder<List<Customer>>(
          future: _topCustomersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: AppConstants.paddingMd,
                child: LoadingState(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: AppConstants.paddingMd,
                child: EmptyState(
                  icon: Icons.person_outline,
                  title: 'لا يوجد عملاء',
                  message: 'لا توجد بيانات كافية لعرض العميل المميز',
                ),
              );
            }

            final topCustomer = snapshot.data!.first;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              child: _buildCustomerCard(topCustomer),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // بناء بطاقة العميل
  // ===========================================================================
  Widget _buildCustomerCard(Customer customer) {
    final hasImage = customer.imagePath != null && 
                     customer.imagePath!.isNotEmpty;

    return CustomCard(
      child: Row(
        children: [
          // --- صورة العميل ---
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primaryLight.withOpacity(0.1),
            backgroundImage: hasImage 
              ? FileImage(File(customer.imagePath!)) 
              : null,
            child: !hasImage 
              ? Icon(
                  Icons.person,
                  size: 35,
                  color: AppColors.primaryLight,
                )
              : null,
          ),
          
          const SizedBox(width: AppConstants.spacingMd),
          
          // --- معلومات العميل ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  'العميل الأكثر شراءً هذا الشهر',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // --- أيقونة التاج ---
          Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 40,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // بناء الإحصائيات الإضافية
  // ===========================================================================
  Widget _buildAdditionalStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsMapFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- عنوان القسم ---
            Text(
              'إحصائيات عامة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- الصف الأول ---
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'العملاء',
                    value: '${stats['totalCustomers']}',
                    icon: Icons.people,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: StatCard(
                    label: 'المنتجات',
                    value: '${stats['totalProducts']}',
                    icon: Icons.inventory_2,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingMd),
            
            // --- الصف الثاني ---
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'مخزون منخفض',
                    value: '${stats['lowStockProducts']}',
                    icon: Icons.warning,
                    color: AppColors.warning,
                    subtitle: 'منتج',
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: StatCard(
                    label: 'مدفوعات معلقة',
                    value: _formatCurrency(stats['pendingPayments']),
                    icon: Icons.pending_actions,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // تنسيق العملة
  // ===========================================================================
  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 د.ع';
    
    final value = amount is double ? amount : double.tryParse(amount.toString()) ?? 0;
    
    // تنسيق بفواصل الآلاف
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} د.ع';
  }
}