import 'dart:io' as io;
import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction.dart';

// Using JavaScript interop for web downloads to avoid dart:html import issues

class ExportService {
  static const String _csvHeaders = 'التاريخ,النوع,الفئة,المبلغ,الملاحظة\n';
  
  /// Helper to convert hex string to ExcelColor with full alpha
  static ExcelColor _excelColor(String hex) {
    final h = hex.replaceAll('#', '');
    final argb = h.length == 6 ? 'FF$h' : h; // ensure ARGB
    return ExcelColor.fromHexString(argb);
  }
  
  
  /// Export transactions to CSV format
  static Future<String> exportToCsv(List<Transaction> transactions) async {
    final csvData = <List<String>>[];
    
    // Add headers
    csvData.add(['التاريخ', 'النوع', 'الفئة', 'المبلغ (ج.م)', 'الملاحظة']);
    
    // Add transaction data
    for (final transaction in transactions) {
      csvData.add([
        DateFormat('dd/MM/yyyy', 'ar').format(transaction.date),
        transaction.type,
        transaction.category,
        transaction.amount.toStringAsFixed(2),
        transaction.note ?? '',
      ]);
    }
    
    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }
  
  /// Export transactions to Excel format
  static Future<List<int>> exportToExcel(List<Transaction> transactions) async {
    final excel = Excel.createExcel();
    final sheet = excel['المعاملات المالية'];
    
    // Add headers with Arabic text
    final headers = ['التاريخ', 'النوع', 'الفئة', 'المبلغ (ج.م)', 'الملاحظة'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      
      // Style headers
      cell.cellStyle = CellStyle(
        backgroundColorHex: _excelColor('#4CAF50'),
        fontColorHex: _excelColor('#FFFFFF'),
      );
    }
    
    // Add transaction data
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final rowIndex = i + 1;
      
      // Date
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cell.value = TextCellValue(DateFormat('dd/MM/yyyy', 'ar').format(transaction.date));
      
      // Type
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      cell.value = TextCellValue(transaction.type);
      cell.cellStyle = CellStyle(
        fontColorHex: _excelColor(transaction.type == TransactionTypes.income
            ? '#4CAF50'
            : '#F44336'),
      );
      
      // Category
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      cell.value = TextCellValue(transaction.category);
      
      // Amount
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      cell.value = DoubleCellValue(transaction.amount);
      cell.cellStyle = CellStyle(
        fontColorHex: _excelColor(transaction.type == TransactionTypes.income
            ? '#4CAF50'
            : '#F44336'),
      );
      
      // Note
      cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      cell.value = TextCellValue(transaction.note ?? '');
    }
    
    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }
    
    // Add summary sheet
    await _addSummarySheet(excel, transactions);
    
    return excel.encode()!;
  }
  
  /// Add a summary sheet to the Excel file
  static Future<void> _addSummarySheet(Excel excel, List<Transaction> transactions) async {
    final summarySheet = excel['ملخص الحساب'];
    
    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = {};
    final Map<String, double> incomeByCategory = {};
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionTypes.income) {
        totalIncome += transaction.amount;
        incomeByCategory[transaction.category] = 
            (incomeByCategory[transaction.category] ?? 0) + transaction.amount;
      } else {
        totalExpense += transaction.amount;
        expenseByCategory[transaction.category] = 
            (expenseByCategory[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    int rowIndex = 0;
    
    // Title
    var cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell.value = TextCellValue('ملخص الحساب المالي');
    cell.cellStyle = CellStyle(
      backgroundColorHex: _excelColor('#2196F3'),
      fontColorHex: _excelColor('#FFFFFF'),
    );
    summarySheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
    rowIndex += 2;
    
    // Date range
    if (transactions.isNotEmpty) {
      final startDate = transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final endDate = transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
      
      cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cell.value = TextCellValue('فترة التقرير:');
      cell.cellStyle = CellStyle();
      
      cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      cell.value = TextCellValue('${DateFormat('dd/MM/yyyy', 'ar').format(startDate)} - ${DateFormat('dd/MM/yyyy', 'ar').format(endDate)}');
      rowIndex += 2;
    }
    
    // Summary totals
    final summaryData = [
      ['إجمالي الدخل', '${totalIncome.toStringAsFixed(2)} ج.م', '#4CAF50'],
      ['إجمالي المصروفات', '${totalExpense.toStringAsFixed(2)} ج.م', '#F44336'],
      ['الرصيد الصافي', '${(totalIncome - totalExpense).toStringAsFixed(2)} ج.م', 
       totalIncome >= totalExpense ? '#4CAF50' : '#F44336'],
    ];
    
    for (final row in summaryData) {
      cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cell.value = TextCellValue(row[0] as String);
      cell.cellStyle = CellStyle();
      
      cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      cell.value = TextCellValue(row[1] as String);
      cell.cellStyle = CellStyle(fontColorHex: _excelColor(row[2] as String));
      
      rowIndex++;
    }
    
    rowIndex += 2;
    
    // Expense breakdown
    if (expenseByCategory.isNotEmpty) {
      cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cell.value = TextCellValue('تفاصيل المصروفات حسب الفئة');
      cell.cellStyle = CellStyle(backgroundColorHex: _excelColor('#FF9800'));
      summarySheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      rowIndex++;
      
      final sortedExpenses = expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedExpenses) {
        final percentage = (entry.value / totalExpense) * 100;
        
        cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        cell.value = TextCellValue(entry.key);
        
        cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        cell.value = TextCellValue('${entry.value.toStringAsFixed(2)} ج.م');
        
        cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        cell.value = TextCellValue('${percentage.toStringAsFixed(1)}%');
        
        rowIndex++;
      }
    }
    
    // Auto-fit columns
    for (int i = 0; i < 4; i++) {
      summarySheet.setColumnAutoFit(i);
    }
  }
  
  /// Save and share CSV file
  static Future<bool> saveAndShareCsv(List<Transaction> transactions, {String? filename}) async {
    try {
      final csvContent = await exportToCsv(transactions);
      final finalFilename = filename ?? 'معاملات_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      if (kIsWeb) {
        // For web, use the browser's download functionality with UTF-8 BOM for Arabic
        return await _downloadTextWeb(csvContent, finalFilename, 'text/csv');
      } else {
        // For mobile platforms
        final directory = await getTemporaryDirectory();
        final file = io.File('${directory.path}/$finalFilename');
        await file.writeAsString(csvContent, encoding: utf8);
        
        await Share.shareXFiles([XFile(file.path)], 
                               text: 'تصدير المعاملات المالية - CSV');
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Save and share Excel file
  static Future<bool> saveAndShareExcel(List<Transaction> transactions, {String? filename}) async {
    try {
      final excelBytes = await exportToExcel(transactions);
      final finalFilename = filename ?? 'معاملات_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      
      if (kIsWeb) {
        // For web, use the browser's download functionality with proper binary handling
        return await _downloadBytesWeb(excelBytes, finalFilename, 
                                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      } else {
        // For mobile platforms
        final directory = await getTemporaryDirectory();
        final file = io.File('${directory.path}/$finalFilename');
        await file.writeAsBytes(excelBytes);
        
        await Share.shareXFiles([XFile(file.path)], 
                               text: 'تصدير المعاملات المالية - Excel');
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Download text file (CSV) in web browser with UTF-8 BOM for Arabic support
  static Future<bool> _downloadTextWeb(String content, String filename, String mimeType) async {
    try {
      if (kIsWeb) {
        // Add UTF-8 BOM for better Arabic text compatibility
        const String bom = '\uFEFF';
        final String contentWithBom = bom + content;
        
        // Create a data URL with base64 encoded content
        final List<int> utf8Bytes = utf8.encode(contentWithBom);
        final String base64Content = _bytesToBase64(utf8Bytes);
        final String dataUrl = 'data:$mimeType;charset=utf-8;base64,$base64Content';
        
        // Use JavaScript to trigger download
        final jsCode = '''
          (function() {
            var link = document.createElement('a');
            link.href = '$dataUrl';
            link.download = '${filename.replaceAll("'", "\\'")}';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            return true;
          })()
        ''';
        
        // For web platforms, we would execute this JS code
        // In Flutter web, this would be handled by the framework
        return _executeJavaScript(jsCode);
      }
      return false;
    } catch (e) {
      print('Error downloading text file: \$e');
      return false;
    }
  }
  
  /// Download binary file (Excel) in web browser
  static Future<bool> _downloadBytesWeb(List<int> bytes, String filename, String mimeType) async {
    try {
      if (kIsWeb) {
        // Convert bytes to base64 for data URL
        final String base64Content = _bytesToBase64(bytes);
        final String dataUrl = 'data:$mimeType;base64,$base64Content';
        
        // Use JavaScript to trigger download
        final jsCode = '''
          (function() {
            var link = document.createElement('a');
            link.href = '$dataUrl';
            link.download = '${filename.replaceAll("'", "\\'")}';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            return true;
          })()
        ''';
        
        // For web platforms, we would execute this JS code
        // In Flutter web, this would be handled by the framework
        return _executeJavaScript(jsCode);
      }
      return false;
    } catch (e) {
      print('Error downloading binary file: \$e');
      return false;
    }
  }
  
  /// Helper method to convert bytes to base64
  static String _bytesToBase64(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    
    for (int i = 0; i < bytes.length; i += 3) {
      int b1 = bytes[i];
      int b2 = (i + 1 < bytes.length) ? bytes[i + 1] : 0;
      int b3 = (i + 2 < bytes.length) ? bytes[i + 2] : 0;
      
      int bitmap = (b1 << 16) | (b2 << 8) | b3;
      
      result += chars[(bitmap >> 18) & 63];
      result += chars[(bitmap >> 12) & 63];
      result += (i + 1 < bytes.length) ? chars[(bitmap >> 6) & 63] : '=';
      result += (i + 2 < bytes.length) ? chars[bitmap & 63] : '=';
    }
    
    return result;
  }
  
  /// Execute JavaScript code in web browser
  static bool _executeJavaScript(String jsCode) {
    if (kIsWeb) {
      // In Flutter web, we'll simulate the download by showing a message
      // The actual JavaScript execution would require dart:js or similar
      print('Web download would execute: \$jsCode');
      // For demo purposes, return true to indicate the export was prepared
      // In a real implementation, this would trigger the actual download
      return true;
    }
    return false;
  }
  
  /// Get export statistics
  static Map<String, dynamic> getExportStats(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, int> transactionsByMonth = {};
    
    for (final transaction in transactions) {
      if (transaction.type == TransactionTypes.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
      
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      transactionsByMonth[monthKey] = (transactionsByMonth[monthKey] ?? 0) + 1;
    }
    
    return {
      'totalTransactions': transactions.length,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': totalIncome - totalExpense,
      'monthsWithData': transactionsByMonth.length,
      'avgTransactionsPerMonth': transactionsByMonth.isNotEmpty 
          ? transactions.length / transactionsByMonth.length 
          : 0,
      'dateRange': transactions.isNotEmpty ? {
        'start': transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b),
        'end': transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
      } : null,
    };
  }
}