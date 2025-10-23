// // lib/screens/archive/archive_center_screen.dart

// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class ArchiveCenterScreen extends StatefulWidget {
//   const ArchiveCenterScreen({super.key});

//   @override
//   State<ArchiveCenterScreen> createState() => _ArchiveCenterScreenState();
// }

// class _ArchiveCenterScreenState extends State<ArchiveCenterScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: Colors.transparent, // مهم جداً
//       extendBodyBehindAppBar: true,

//       // --- ✅✅✅ بداية التعديل الجذري ✅✅✅ ---
//       // 1. نضع الخلفية المتدرجة هنا لتغطي الشاشة بأكملها
//       body: GradientBackground(
//         // 2. نضع NestedScrollView داخل الخلفية الشاملة
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) {
//             return [
//               SliverAppBar(
//                 title: Text(l10n.archiveCenter),
//                 pinned: true,
//                 floating: true,
//                 backgroundColor: Colors.transparent, // شريط العنوان نفسه شفاف
//                 // الخلفية الزجاجية ستظهر الآن فوق التدرج اللوني
//                 flexibleSpace: const GlassContainer(
//                   borderRadius: 0,
//                   child: SizedBox.shrink(),
//                 ),
//                 bottom: TabBar(
//                   controller: _tabController,
//                   labelColor: theme.colorScheme.primary,
//                   unselectedLabelColor: AppColors.textGrey,
//                   indicator: UnderlineTabIndicator(
//                     borderSide: BorderSide(width: 3.0, color: theme.colorScheme.primary),
//                     insets: const EdgeInsets.symmetric(horizontal: 40.0),
//                   ),
//                   tabs: [
//                     Tab(icon: const Icon(Icons.people_outline), text: l10n.customers),
//                     Tab(icon: const Icon(Icons.store_outlined), text: l10n.suppliers),
//                     Tab(icon: const Icon(Icons.inventory_2_outlined), text: l10n.products),
//                   ],
//                 ),
//               ),
//             ];
//           },
//           // 3. جسم NestedScrollView الآن لا يحتاج إلى خلفية خاصة به
//           body: TabBarView(
//             controller: _tabController,
//             children: [
//               _ArchivedItemsList(itemType: _ItemType.customer, l10n: l10n),
//               _ArchivedItemsList(itemType: _ItemType.supplier, l10n: l10n),
//               _ArchivedItemsList(itemType: _ItemType.product, l10n: l10n),
//             ],
//           ),
//         ),
//       ),
//       // --- ⏹️⏹️⏹️ نهاية التعديل الجذري ⏹️⏹️⏹️ ---
//     );
//   }
// }

// // ... باقي الكود (ويدجت _ArchivedItemsList) يبقى كما هو بدون أي تغيير.
// // ... (enum _ItemType يبقى كما هو)
// enum _ItemType { customer, supplier, product }

// class _ArchivedItemsList extends StatefulWidget {
//   final _ItemType itemType;
//   final AppLocalizations l10n;
//   const _ArchivedItemsList({required this.itemType, required this.l10n});

//   @override
//   State<_ArchivedItemsList> createState() => __ArchivedItemsListState();
// }

// class __ArchivedItemsListState extends State<_ArchivedItemsList> {
//   // ... (كل المتغيرات والدوال المنطقية تبقى كما هي)
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   late Future<List<dynamic>> _archivedItemsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadArchivedItems();
//   }

//   void _loadArchivedItems() {
//     setState(() {
//       switch (widget.itemType) {
//         case _ItemType.customer:
//           _archivedItemsFuture = dbHelper.getArchivedCustomers();
//           break;
//         case _ItemType.supplier:
//           _archivedItemsFuture = dbHelper.getArchivedSuppliers();
//           break;
//         case _ItemType.product:
//           _archivedItemsFuture = dbHelper.getArchivedProductsWithSupplierName();
//           break;
//       }
//     });
//   }

//   Future<void> _restoreItem(dynamic item) async {
//     String tableName;
//     String idColumn;
//     int id;
//     String name;

//     switch (widget.itemType) {
//       case _ItemType.customer:
//         tableName = 'TB_Customer';
//         idColumn = 'CustomerID';
//         id = (item as Customer).customerID!;
//         name = (item as Customer).customerName;
//         break;
//       case _ItemType.supplier:
//         tableName = 'TB_Suppliers';
//         idColumn = 'SupplierID';
//         id = (item as Supplier).supplierID!;
//         name = (item as Supplier).supplierName;
//         break;
//       case _ItemType.product:
//         tableName = 'Store_Products';
//         idColumn = 'ProductID';
//         id = (item as Product).productID!;
//         name = (item as Product).productName;
//         break;
//     }

//     await dbHelper.restoreItem(tableName, idColumn, id);
//     await dbHelper.logActivity('استعادة العنصر: $name', userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(widget.l10n.itemRestoredSuccess(name)), backgroundColor: Colors.green),
//       );
//     }

//     _loadArchivedItems();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return FutureBuilder<List<dynamic>>(
//       future: _archivedItemsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Colors.white));
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text(widget.l10n.noArchivedItems, style: theme.textTheme.bodyLarge));
//         }

//         final items = snapshot.data!;
//         return ListView.builder(
//           padding: const EdgeInsets.all(12), // إضافة padding حول القائمة
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             final item = items[index];
//             return _buildListItem(item, theme);
//           },
//         );
//       },
//     );
//   }

//   // 5. ويدجت بناء عنصر القائمة الزجاجي
//   Widget _buildListItem(dynamic item, ThemeData theme) {
//     String title = '';
//     String subtitle = '';
//     File? imageFile;
//     IconData icon = Icons.help;
//     final l10n = widget.l10n;

//     if (item is Customer) {
//       title = item.customerName;
//       subtitle = l10n.archivedCustomer;
//       icon = Icons.person_outline;
//       if (item.imagePath != null && item.imagePath!.isNotEmpty) imageFile = File(item.imagePath!);
//     } else if (item is Supplier) {
//       title = item.supplierName;
//       subtitle = l10n.archivedSupplier;
//       icon = Icons.store_outlined;
//       if (item.imagePath != null && item.imagePath!.isNotEmpty) imageFile = File(item.imagePath!);
//     } else if (item is Product) {
//       title = item.productName;
//       subtitle = l10n.archivedProduct(item.supplierName ?? l10n.unknown);
//       icon = Icons.inventory_2_outlined;
//     }

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: GlassContainer(
//         borderRadius: 15,
//         child: ListTile(
//           leading: CircleAvatar(
//             backgroundColor: AppColors.primaryPurple.withOpacity(0.5),
//             backgroundImage: imageFile != null && imageFile.existsSync() ? FileImage(imageFile) : null,
//             child: (imageFile == null || !imageFile.existsSync()) ? Icon(icon, color: AppColors.textGrey) : null,
//           ),
//           title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
//           subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
//           trailing: ElevatedButton(
//             onPressed: () => _restoreItem(item),
//             // 6. توحيد تصميم الزر
//             style: ElevatedButton.styleFrom(
//               backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
//               foregroundColor: theme.colorScheme.primary,
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//             ),
//             child: Text(l10n.restore),
//           ),
//         ),
//       ),
//     );
//   }
// }
