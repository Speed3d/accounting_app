// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';

// ============= استيراد الملفات =============
import '../../data/database_helper.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../layouts/main_layout.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_state.dart';
import '../../utils/helpers.dart'; // لاستخدام formatCurrency

/// ===========================================================================
/// لوحة التحكم الرئيسية (Dashboard Screen)
/// ===========================================================================
/// الغرض:
/// - عرض إحصائيات سريعة عن النشاط التجاري
/// - إظهار أهم المنتجات والعملاء
/// - ملخص المبيعات والأرباح اليومية/الشهرية
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
    _statsMapFuture = _fetchDashboardStats();
  }

  // ===========================================================================
  // جلب إحصائيات Dashboard
  // ===========================================================================
  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    // TODO: استبدل هذا بدوال حقيقية من database_helper
    // يمكنك إنشاء دوال مثل:
    // - getTodaySales()
    // - getTodayProfit()
    // - getMonthSales()
    // - getMonthProfit()
    // إلخ...
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'todaySales': 1250000.0,
      'todayProfit': 350000.0,
      'monthSales': 15000000.0,
      'monthProfit': 4200000.0,
      'totalCustomers': 45,
      'totalProducts': 230,
      'lowStockProducts': 12,
      'pendingPayments': 2500000.0,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(

    // === AppBar بسيط ===
    appBar: AppBar(
      title: Text(l10n.dashboard),
      // زر الرجوع يظهر تلقائياً
    ),

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
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsMapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: LoadingState(message: l10n.loadingStats),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return  EmptyState(
            icon: Icons.error_outline,
            title: l10n.errorLoadingData, 
          message: l10n.pleaseTryAgain,
          );
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- عنوان القسم ---
            Text(
              l10n.today,
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
                    title: l10n.sales,
                    value: formatCurrency(stats['todaySales']),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: InfoCard(
                    title: l10n.profit,
                    value: formatCurrency(stats['todayProfit']),
                    icon: Icons.attach_money,
                    color: AppColors.profit,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // --- عنوان القسم ---
            Text(
              l10n.thisMonth,
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
                    title: l10n.sales,
                    value: formatCurrency(stats['monthSales']),
                    icon: Icons.shopping_cart,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: InfoCard(
                    title: l10n.profit,
                    value: formatCurrency(stats['monthProfit']),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.topSelling,
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
              return  Padding(
                padding: AppConstants.paddingMd,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.noSales,
                  message: l10n.noSalesData,
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
  // بناء بطاقة المنتج (بدون صور - فقط أيقونات)
  // ===========================================================================
  Widget _buildProductCard(Product product) {
    final l10n = AppLocalizations.of(context)!;
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
              '${l10n.available}: ${product.quantity}',
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.topCustomer,
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
              return  Padding(
                padding: AppConstants.paddingMd,
                child: EmptyState(
                  icon: Icons.person_outline,
                  title: l10n.noCustomers, // ← استخدم التدوين
                message: l10n.noCustomersData,
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
  // بناء بطاقة العميل (مع دعم الصور)
  // ===========================================================================
  Widget _buildCustomerCard(Customer customer) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ التحقق من وجود الصورة (Customer يدعم imagePath)
    final hasImage = customer.imagePath != null && 
                     customer.imagePath!.isNotEmpty &&
                     File(customer.imagePath!).existsSync();

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
                  l10n.topBuyerThisMonth,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // --- أيقونة التاج ---
          const Icon(
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.generalStats,
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
                    label: l10n.totalCustomers,
                    value: '${stats['totalCustomers']}',
                    icon: Icons.people,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: StatCard(
                    label: l10n.totalProducts,
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
                    label: l10n.lowStock,
                    value: '${stats['lowStockProducts']}',
                    icon: Icons.warning,
                    color: AppColors.warning,
                    subtitle: l10n.product,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: StatCard(
                    label: l10n.pendingPayments,
                    value: formatCurrency(stats['pendingPayments']),
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
}