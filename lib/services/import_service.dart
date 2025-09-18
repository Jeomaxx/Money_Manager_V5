import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ImportService {
  /// Parse and validate transactions from CSV content
  static Future<ImportResult> importFromCsv(String csvContent) async {
    try {
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);
      
      if (csvData.isEmpty) {
        return ImportResult(
          success: false,
          message: 'الملف فارغ أو غير صالح',
          transactions: [],
          errors: ['الملف لا يحتوي على بيانات'],
        );
      }
      
      // Skip header row if it contains text headers
      int startIndex = 0;
      if (csvData.isNotEmpty && csvData[0].any((cell) => cell.toString().contains('التاريخ') || cell.toString().contains('النوع'))) {
        startIndex = 1;
      }
      
      final List<Transaction> transactions = [];
      final List<String> errors = [];
      
      for (int i = startIndex; i < csvData.length; i++) {
        final row = csvData[i];
        final rowNumber = i + 1;
        
        try {
          if (row.length < 4) {
            errors.add('الصف $rowNumber: عدد الأعمدة غير كافي (يجب أن يكون 4 أو 5 أعمدة على الأقل)');
            continue;
          }
          
          // Parse date (column 0)
          DateTime? date;
          final dateStr = row[0].toString().trim();
          if (dateStr.isEmpty) {
            errors.add('الصف $rowNumber: التاريخ مطلوب');
            continue;
          }
          
          // Try different date formats
          try {
            if (dateStr.contains('/')) {
              // DD/MM/YYYY or MM/DD/YYYY
              final parts = dateStr.split('/');
              if (parts.length == 3) {
                // Assume DD/MM/YYYY format for Arabic locale
                date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              }
            } else if (dateStr.contains('-')) {
              // YYYY-MM-DD format
              date = DateTime.parse(dateStr);
            } else {
              // Try parsing as is
              date = DateTime.parse(dateStr);
            }
          } catch (e) {
            errors.add('الصف $rowNumber: تنسيق التاريخ غير صحيح: $dateStr (استخدم DD/MM/YYYY أو YYYY-MM-DD)');
            continue;
          }
          
          // Parse type (column 1)
          final typeStr = row[1].toString().trim();
          if (typeStr.isEmpty) {
            errors.add('الصف $rowNumber: نوع المعاملة مطلوب');
            continue;
          }
          
          String type;
          if (typeStr == 'دخل' || typeStr.toLowerCase() == 'income' || typeStr == TransactionTypes.income) {
            type = TransactionTypes.income;
          } else if (typeStr == 'مصروف' || typeStr.toLowerCase() == 'expense' || typeStr == TransactionTypes.expense) {
            type = TransactionTypes.expense;
          } else {
            errors.add('الصف $rowNumber: نوع المعاملة غير صحيح: $typeStr (يجب أن يكون "دخل" أو "مصروف")');
            continue;
          }
          
          // Parse category (column 2)
          final category = row[2].toString().trim();
          if (category.isEmpty) {
            errors.add('الصف $rowNumber: الفئة مطلوبة');
            continue;
          }
          
          // Parse amount (column 3)
          double? amount;
          final amountStr = row[3].toString().trim().replaceAll('ج.م', '').replaceAll(',', '');
          if (amountStr.isEmpty) {
            errors.add('الصف $rowNumber: المبلغ مطلوب');
            continue;
          }
          
          try {
            amount = double.parse(amountStr);
            if (amount <= 0) {
              errors.add('الصف $rowNumber: المبلغ يجب أن يكون أكبر من الصفر');
              continue;
            }
          } catch (e) {
            errors.add('الصف $rowNumber: المبلغ غير صحيح: $amountStr');
            continue;
          }
          
          // Parse note (column 4, optional)
          String? note;
          if (row.length > 4) {
            note = row[4].toString().trim();
            if (note.isEmpty) note = null;
          }
          
          // Create transaction
          final transaction = Transaction(
            amount: amount,
            type: type,
            category: category,
            note: note,
            date: date ?? DateTime.now(),
          );
          
          transactions.add(transaction);
        } catch (e) {
          errors.add('الصف $rowNumber: خطأ في معالجة البيانات: $e');
        }
      }
      
      return ImportResult(
        success: errors.isEmpty || transactions.isNotEmpty,
        message: errors.isEmpty 
            ? 'تم استيراد ${transactions.length} معاملة بنجاح'
            : 'تم استيراد ${transactions.length} معاملة مع ${errors.length} خطأ',
        transactions: transactions,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'خطأ في قراءة الملف: $e',
        transactions: [],
        errors: ['خطأ في قراءة الملف: $e'],
      );
    }
  }
  
  /// Parse and validate transactions from Excel-like CSV content
  /// (Similar to CSV but with different column handling)
  static Future<ImportResult> importFromExcel(String csvContent) async {
    // For now, Excel import uses the same CSV parsing logic
    // In a real implementation, you would use an Excel library
    return await importFromCsv(csvContent);
  }
  
  /// Validate a single transaction against business rules
  static List<String> validateTransaction(Transaction transaction) {
    final errors = <String>[];
    
    if (transaction.amount <= 0) {
      errors.add('المبلغ يجب أن يكون أكبر من الصفر');
    }
    
    if (transaction.type != TransactionTypes.income && transaction.type != TransactionTypes.expense) {
      errors.add('نوع المعاملة يجب أن يكون "دخل" أو "مصروف"');
    }
    
    if (transaction.category.trim().isEmpty) {
      errors.add('الفئة مطلوبة');
    }
    
    if (transaction.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('تاريخ المعاملة لا يمكن أن يكون في المستقبل');
    }
    
    // Check if category is valid for the transaction type
    if (transaction.type == TransactionTypes.income) {
      if (!TransactionCategories.incomeCategories.contains(transaction.category) && 
          !_isCustomCategory(transaction.category)) {
        errors.add('فئة الدخل غير صحيحة: ${transaction.category}');
      }
    } else {
      if (!TransactionCategories.expenseCategories.contains(transaction.category) && 
          !_isCustomCategory(transaction.category)) {
        errors.add('فئة المصروف غير صحيحة: ${transaction.category}');
      }
    }
    
    return errors;
  }
  
  /// Check if a category is a custom user-defined category
  static bool _isCustomCategory(String category) {
    // For now, accept any non-empty category as custom
    // In a real app, you might maintain a list of custom categories
    return category.trim().isNotEmpty;
  }
  
  /// Get template CSV content for users to download and fill
  static String getImportTemplate() {
    final csvData = <List<String>>[
      ['التاريخ', 'النوع', 'الفئة', 'المبلغ (ج.م)', 'الملاحظة'],
      ['01/01/2024', 'دخل', 'راتب', '5000.00', 'راتب شهر يناير'],
      ['02/01/2024', 'مصروف', 'طعام', '300.00', 'تسوق البقالة'],
      ['03/01/2024', 'مصروف', 'مواصلات', '150.00', 'بنزين السيارة'],
      ['04/01/2024', 'دخل', 'مكافأة', '1000.00', 'مكافأة نهاية العام'],
    ];
    
    return const ListToCsvConverter().convert(csvData);
  }
  
  /// Get instructions for the import format in Arabic
  static String getImportInstructions() {
    return '''
تعليمات استيراد البيانات:

1. تنسيق الملف:
   - يجب أن يكون الملف بصيغة CSV
   - الترميز: UTF-8
   - الأعمدة المطلوبة: التاريخ، النوع، الفئة، المبلغ، الملاحظة (اختيارية)

2. تنسيق البيانات:
   - التاريخ: DD/MM/YYYY أو YYYY-MM-DD
   - النوع: "دخل" أو "مصروف"
   - الفئة: أي فئة صحيحة أو فئة مخصصة
   - المبلغ: رقم موجب بدون رموز العملة
   - الملاحظة: نص اختياري

3. مثال:
   01/01/2024,دخل,راتب,5000.00,راتب شهر يناير
   02/01/2024,مصروف,طعام,300.00,تسوق البقالة

4. نصائح:
   - تأكد من صحة تنسيق التاريخ
   - استخدم النقطة (.) كفاصل عشري
   - تجنب استخدام الفواصل (،) في الأرقام
   - يمكن ترك عمود الملاحظة فارغاً
''';
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final String message;
  final List<Transaction> transactions;
  final List<String> errors;
  
  ImportResult({
    required this.success,
    required this.message,
    required this.transactions,
    required this.errors,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasTransactions => transactions.isNotEmpty;
  int get successCount => transactions.length;
  int get errorCount => errors.length;
}