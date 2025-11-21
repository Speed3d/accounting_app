// // lib/services/database_migration_service.dart

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite_new;
// import 'package:sqflite_sqlcipher/sqflite.dart';
// import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite_old;
// import 'database_key_manager.dart';

// /// 🔄 خدمة ترحيل قاعدة البيانات من غير مشفرة إلى مشفرة
// /// 
// /// ← Hint: تُستخدم مرة واحدة فقط عند أول تحديث
// class DatabaseMigrationService {
//   static const String _dbFileName = "accounting.db";
//   static const String _oldDbBackup = "accounting.db.old";

//   /// ترحيل قاعدة البيانات القديمة إلى مشفرة
//   /// 
//   /// ← Hint: الخطوات:
//   ///   1. التحقق من وجود قاعدة بيانات قديمة
//   ///   2. إنشاء نسخة احتياطية
//   ///   3. قراءة البيانات من القديمة
//   ///   4. كتابتها في المشفرة الجديدة
//   ///   5. حذف القديمة
//   static Future<bool> migrateIfNeeded() async {
//     try {
//       final documentsDirectory = await getApplicationDocumentsDirectory();
//       final oldDbPath = p.join(documentsDirectory.path, _dbFileName);
//       final oldDbFile = File(oldDbPath);

//       // ← Hint: التحقق من وجود قاعدة بيانات غير مشفرة
//       if (!await oldDbFile.exists()) {
//         debugPrint('ℹ️ لا توجد قاعدة بيانات قديمة للترحيل');
//         return false;
//       }

//       // ← Hint: التحقق إذا كانت مشفرة بالفعل
//       if (await _isDatabaseEncrypted(oldDbPath)) {
//         debugPrint('✅ قاعدة البيانات مشفرة بالفعل');
//         return false;
//       }

//       debugPrint('🔄 بدء ترحيل قاعدة البيانات...');

//       // ============================================================================
//       // الخطوة 1: نسخ احتياطي من القاعدة القديمة
//       // ============================================================================
      
//       final backupPath = p.join(documentsDirectory.path, _oldDbBackup);
//       await oldDbFile.copy(backupPath);
//       debugPrint('✅ تم إنشاء نسخة احتياطية: $backupPath');

//       // ============================================================================
//       // الخطوة 2: قراءة البيانات من القاعدة القديمة
//       // ============================================================================
      
//       final oldDb = await sqflite_old.openDatabase(oldDbPath);
      
//       // ← Hint: قائمة الجداول التي نريد ترحيلها
//       final tablesToMigrate = [
//         'TB_Users',
//         'TB_Employees',
//         'TB_Payroll',
//         'TB_Employee_Advances',
//         'TB_Suppliers',
//         'Supplier_Partners',
//         'TB_Profit_Withdrawals',
//         'Store_Products',
//         'TB_Customer',
//         'Debt_Customer',
//         'Payment_Customer',
//         'TB_Settings',
//         'Sales_Returns',
//         'Activity_Log',
//         'TB_App_State',
//         'TB_Invoices',
//         'TB_Expenses',
//         'TB_Expense_Categories',
//       ];

//       final allData = <String, List<Map<String, dynamic>>>{};
      
//       for (final table in tablesToMigrate) {
//         try {
//           final data = await oldDb.query(table);
//           allData[table] = data;
//           debugPrint('  ✅ قراءة جدول $table: ${data.length} صف');
//         } catch (e) {
//           debugPrint('  ⚠️ تخطي جدول $table (قد لا يكون موجوداً): $e');
//         }
//       }

//       await oldDb.close();

//       // ============================================================================
//       // الخطوة 3: حذف القاعدة القديمة
//       // ============================================================================
      
//       await oldDbFile.delete();
//       debugPrint('✅ تم حذف القاعدة القديمة');

//       // ============================================================================
//       // الخطوة 4: إنشاء قاعدة مشفرة جديدة
//       // ============================================================================
      
//       final encryptionKey = await DatabaseKeyManager.instance.getDatabaseKey();
      
//       // ← Hint: سنستورد DatabaseHelper لإنشاء الهيكل
//       // لكن لا نستطيع لأنه سيسبب circular dependency
//       // الحل: نستخدم openDatabase مباشرة مع onCreate بسيط
      
//       final newDb = await sqflite_new.openDatabase(
//         oldDbPath,
//         password: encryptionKey,
//         version: 1,
//         onCreate: (db, version) async {
//           // ← Hint: سيتم استدعاء onCreate من DatabaseHelper تلقائياً
//           debugPrint('✅ تم إنشاء قاعدة البيانات المشفرة');
//         },
//       );

//       // ============================================================================
//       // الخطوة 5: نسخ البيانات إلى القاعدة المشفرة
//       // ============================================================================
      
//       debugPrint('🔄 نسخ البيانات إلى القاعدة المشفرة...');
      
//       for (final entry in allData.entries) {
//         final table = entry.key;
//         final rows = entry.value;
        
//         if (rows.isEmpty) continue;
        
//         final batch = newDb.batch();
        
//         for (final row in rows) {
//           batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
//         }
        
//         await batch.commit(noResult: true);
//         debugPrint('  ✅ نسخ جدول $table: ${rows.length} صف');
//       }

//       await newDb.close();

//       debugPrint('✅ اكتمل الترحيل بنجاح!');
//       debugPrint('ℹ️ النسخة الاحتياطية محفوظة في: $backupPath');

//       return true;

//     } catch (e, stackTrace) {
//       debugPrint('❌ خطأ في ترحيل قاعدة البيانات: $e');
//       debugPrint('Stack trace: $stackTrace');
//       return false;
//     }
//   }

//   /// التحقق إذا كانت قاعدة البيانات مشفرة
//   static Future<bool> _isDatabaseEncrypted(String path) async {
//     try {
//       // ← Hint: محاولة فتحها بدون كلمة مرور
//       final db = await sqflite_old.openDatabase(path);
//       await db.close();
      
//       // ← Hint: إذا نجحت، فهي غير مشفرة
//       return false;
//     } catch (e) {
//       // ← Hint: إذا فشلت، فهي مشفرة (أو تالفة)
//       return true;
//     }
//   }

//   /// حذف النسخة الاحتياطية القديمة
//   static Future<void> deleteBackup() async {
//     try {
//       final documentsDirectory = await getApplicationDocumentsDirectory();
//       final backupPath = p.join(documentsDirectory.path, _oldDbBackup);
//       final backupFile = File(backupPath);
      
//       if (await backupFile.exists()) {
//         await backupFile.delete();
//         debugPrint('✅ تم حذف النسخة الاحتياطية القديمة');
//       }
//     } catch (e) {
//       debugPrint('⚠️ خطأ في حذف النسخة الاحتياطية: $e');
//     }
//   }
// }