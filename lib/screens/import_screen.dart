import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:ui' as ui;
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isImporting = false;
  ImportResult? _lastImportResult;
  String? _selectedFileName;
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('استيراد البيانات'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'تعليمات الاستيراد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          ImportService.getImportInstructions(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Template Download Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.download, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'تحميل قالب الاستيراد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'قم بتحميل قالب CSV يحتوي على تنسيق صحيح وأمثلة لتسهيل عملية الاستيراد',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _downloadTemplate,
                        icon: const Icon(Icons.file_download),
                        label: const Text('تحميل القالب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.upload_file, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'اختيار ملف للاستيراد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFileName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.file_present, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'الملف المحدد: $_selectedFileName',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFileName = null;
                                    _lastImportResult = null;
                                  });
                                },
                                icon: const Icon(Icons.close, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isImporting ? null : _selectFile,
                              icon: const Icon(Icons.folder_open),
                              label: Text(_selectedFileName == null ? 'اختيار ملف CSV' : 'اختيار ملف آخر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          if (_selectedFileName != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isImporting ? null : _importFile,
                                icon: _isImporting 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload),
                                label: Text(_isImporting ? 'جاري الاستيراد...' : 'استيراد البيانات'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Import Results
              if (_lastImportResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _lastImportResult!.success ? Icons.check_circle : Icons.error,
                              color: _lastImportResult!.success ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'نتائج الاستيراد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status message
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _lastImportResult!.success 
                                ? Colors.green.shade50 
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _lastImportResult!.success 
                                  ? Colors.green.shade200 
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            _lastImportResult!.message,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _lastImportResult!.success ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Statistics
                        if (_lastImportResult!.hasTransactions || _lastImportResult!.hasErrors) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'المعاملات المستوردة',
                                  '${_lastImportResult!.successCount}',
                                  Colors.green,
                                  Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'الأخطاء',
                                  '${_lastImportResult!.errorCount}',
                                  Colors.red,
                                  Icons.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Error details
                        if (_lastImportResult!.hasErrors) ...[
                          ExpansionTile(
                            title: const Text('تفاصيل الأخطاء'),
                            leading: const Icon(Icons.error_outline, color: Colors.red),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _lastImportResult!.errors.map((error) => 
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(color: Colors.red)),
                                          Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
                                        ],
                                      ),
                                    )
                                  ).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Success actions
                        if (_lastImportResult!.success && _lastImportResult!.hasTransactions) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  icon: const Icon(Icons.home),
                                  label: const Text('العودة للرئيسية'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFileName = null;
                                      _lastImportResult = null;
                                    });
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('استيراد آخر'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final templateContent = ImportService.getImportTemplate();
      final success = await ExportService.saveAndShareCsv(
        [], // Empty list since this is just a template
        filename: 'قالب_استيراد_المعاملات.csv',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل القالب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل القالب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل القالب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _lastImportResult = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importFile() async {
    if (_selectedFileName == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // For web, we'd need to handle file content differently
      // For now, we'll simulate the import process
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null) {
        String fileContent;
        
        if (result.files.single.bytes != null) {
          // Web platform
          fileContent = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          // Mobile platform
          final file = File(result.files.single.path!);
          fileContent = await file.readAsString(encoding: utf8);
        } else {
          throw Exception('لا يمكن قراءة الملف');
        }

        // Parse the CSV content
        final importResult = await ImportService.importFromCsv(fileContent);
        
        // If successful, save the transactions
        if (importResult.success && importResult.hasTransactions) {
          for (final transaction in importResult.transactions) {
            await _transactionService.addTransaction(
              amount: transaction.amount,
              type: transaction.type,
              category: transaction.category,
              note: transaction.note,
              date: transaction.date,
            );
          }
        }

        setState(() {
          _lastImportResult = importResult;
        });
      }
    } catch (e) {
      setState(() {
        _lastImportResult = ImportResult(
          success: false,
          message: 'خطأ في استيراد الملف: $e',
          transactions: [],
          errors: ['خطأ في قراءة الملف: $e'],
        );
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }
}