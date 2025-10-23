// // lib/screens/employees/add_advance_screen.dart

// import 'package:accounting_app/l10n/app_localizations.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/gradient_background.dart';

// class AddAdvanceScreen extends StatefulWidget {
//   final Employee employee;
//   const AddAdvanceScreen({super.key, required this.employee});

//   @override
//   State<AddAdvanceScreen> createState() => _AddAdvanceScreenState();
// }

// class _AddAdvanceScreenState extends State<AddAdvanceScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final _amountController = TextEditingController();
//   final _notesController = TextEditingController();
//   final _dateController = TextEditingController();
//   DateTime _selectedDate = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
//   }

//   @override
//   void dispose() {
//     _amountController.dispose();
//     _notesController.dispose();
//     _dateController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveAdvance() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;

//     try {
//       final amount = double.parse(convertArabicNumbersToEnglish(_amountController.text));
//       final newAdvance = EmployeeAdvance(
//         employeeID: widget.employee.employeeID!,
//         advanceDate: _selectedDate.toIso8601String(),
//         advanceAmount: amount,
//         repaymentStatus: l10n.unpaid,
//         notes: _notesController.text,
//       );
//       await dbHelper.recordNewAdvance(newAdvance);
//       final action = 'تسجيل سلفة للموظف: ${widget.employee.fullName} بقيمة: ${formatCurrency(amount)}';
//       await dbHelper.logActivity(action, userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.advanceAddedSuccess), backgroundColor: Colors.green));
//         Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//       }
//     }
//   }

//   Future<void> _pickDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//       // يمكنك تخصيص تصميم DatePicker هنا ليتناسب مع الثيم
//     );
//     if (pickedDate != null && pickedDate != _selectedDate) {
//       setState(() {
//         _selectedDate = pickedDate;
//         _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       // --- 2. توحيد بنية الصفحة لتتوافق مع التصميم الزجاجي ---
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.newAdvanceFor(widget.employee.fullName)),
//         backgroundColor: Colors.transparent, // جعل شريط العنوان شفافاً
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         // استخدام SafeArea لضمان عدم تداخل المحتوى مع مناطق النظام
//         child: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(20.0),
//               children: [
//                 // --- 3. تطبيق التصميم الزجاجي على حقول الإدخال ---
//                 TextFormField(
//                   controller: _amountController,
//                   decoration: _getGlassInputDecoration(l10n.advanceAmount, Icons.attach_money),
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return l10n.amountRequired;
//                     final amount = double.tryParse(convertArabicNumbersToEnglish(v));
//                     if (amount == null || amount <= 0) return l10n.enterValidAmount;
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _dateController,
//                   decoration: _getGlassInputDecoration(l10n.advanceDate, Icons.calendar_today),
//                   readOnly: true,
//                   onTap: _pickDate,
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _notesController,
//                   decoration: _getGlassInputDecoration(l10n.notesOptional, Icons.notes),
//                   maxLines: 3,
//                 ),
//                 const SizedBox(height: 40),
//                 // --- 4. تطبيق تصميم الزر الموحد ---
//                 ElevatedButton.icon(
//                   onPressed: _saveAdvance,
//                   icon: const Icon(Icons.save),
//                   label: Text(l10n.saveAdvance),
//                   // النمط يأتي مباشرة من ElevatedButtonTheme في app_theme.dart
//                   // لا حاجة لتحديد الألوان أو الحجم هنا
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 5. دالة مساعدة للحصول على تصميم موحد لحقول الإدخال الزجاجية ---
//   InputDecoration _getGlassInputDecoration(String labelText, IconData icon) {
//     final theme = Theme.of(context);
//     return InputDecoration(
//       labelText: labelText,
//       prefixIcon: Icon(icon, color: AppColors.textGrey.withOpacity(0.8)),
//       // الأنماط والألوان تأتي من تعريف TextFormField في ملفنا _GlassTextFormField
//       // الذي أنشأناه سابقاً، ولكن نكررها هنا لسهولة الفهم في هذه الصفحة
//       filled: true,
//       fillColor: AppColors.glassBgColor,
//       labelStyle: theme.textTheme.bodyMedium,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(15),
//         borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(15),
//         borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(15),
//         borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
//       ),
//     );
//   }
// }
