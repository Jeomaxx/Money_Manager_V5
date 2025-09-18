import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  
  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedType;
  String? _selectedCategory;
  
  // Export stats
  Map<String, dynamic> _exportStats = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _transactions = await _transactionService.getAllTransactions();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      // Date filter
      if (_startDate != null && transaction.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transaction.date.isAfter(_endDate!)) {
        return false;
      }
      
      // Type filter
      if (_selectedType != null && transaction.type != _selectedType) {
        return false;
      }
      
      // Category filter
      if (_selectedCategory != null && transaction.category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Update export stats
    _exportStats = ExportService.getExportStats(_filteredTransactions);
    
    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedType = null;
      _selectedCategory = null;
    });
    _applyFilters();
  }

  Future<void> _exportCsv() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للتصدير'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final success = await ExportService.saveAndShareCsv(_filteredTransactions);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'تم تصدير البيانات بصيغة CSV بنجاح'
                : 'فشل في تصدير البيانات',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للتصدير'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final success = await ExportService.saveAndShareExcel(_filteredTransactions);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'تم تصدير البيانات بصيغة Excel بنجاح'
                : 'فشل في تصدير البيانات',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('تصدير البيانات'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filters Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.filter_list, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  'تصفية البيانات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: const Text('مسح الفلاتر'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Date Range
                            ListTile(
                              leading: const Icon(Icons.date_range),
                              title: const Text('الفترة الزمنية'),
                              subtitle: _startDate != null && _endDate != null
                                  ? Text(
                                      '${DateFormat('dd/MM/yyyy', 'ar').format(_startDate!)} - ${DateFormat('dd/MM/yyyy', 'ar').format(_endDate!)}',
                                    )
                                  : const Text('جميع التواريخ'),
                              onTap: _selectDateRange,
                              trailing: const Icon(Icons.arrow_forward_ios),
                            ),
                            
                            // Type Filter
                            ListTile(
                              leading: const Icon(Icons.category),
                              title: const Text('نوع المعاملة'),
                              subtitle: Text(_selectedType ?? 'جميع الأنواع'),
                              onTap: () => _showTypeFilter(),
                              trailing: const Icon(Icons.arrow_forward_ios),
                            ),
                            
                            // Category Filter
                            ListTile(
                              leading: const Icon(Icons.label),
                              title: const Text('الفئة'),
                              subtitle: Text(_selectedCategory ?? 'جميع الفئات'),
                              onTap: () => _showCategoryFilter(),
                              trailing: const Icon(Icons.arrow_forward_ios),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Export Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text(
                                  'إحصائيات التصدير',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (_exportStats.isNotEmpty) ...[
                              _buildStatItem('عدد المعاملات', '${_exportStats['totalTransactions']}'),
                              _buildStatItem('إجمالي الدخل', '${(_exportStats['totalIncome'] as double).toStringAsFixed(2)} ج.م'),
                              _buildStatItem('إجمالي المصروفات', '${(_exportStats['totalExpense'] as double).toStringAsFixed(2)} ج.م'),
                              _buildStatItem('الرصيد الصافي', '${(_exportStats['netBalance'] as double).toStringAsFixed(2)} ج.م',
                                  color: (_exportStats['netBalance'] as double) >= 0 ? Colors.green : Colors.red),
                              if (_exportStats['dateRange'] != null) ...[
                                _buildStatItem('الفترة الزمنية', 
                                  '${DateFormat('dd/MM/yyyy', 'ar').format(_exportStats['dateRange']['start'])} - ${DateFormat('dd/MM/yyyy', 'ar').format(_exportStats['dateRange']['end'])}'),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Export Options
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.file_download, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'خيارات التصدير',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // CSV Export
                            ListTile(
                              leading: const Icon(Icons.table_chart, color: Colors.blue),
                              title: const Text('تصدير CSV'),
                              subtitle: const Text('ملف نصي مناسب للبرامج البسيطة'),
                              trailing: ElevatedButton.icon(
                                onPressed: _filteredTransactions.isEmpty ? null : _exportCsv,
                                icon: const Icon(Icons.download),
                                label: const Text('تصدير'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const Divider(),
                            
                            // Excel Export
                            ListTile(
                              leading: const Icon(Icons.grid_on, color: Colors.green),
                              title: const Text('تصدير Excel'),
                              subtitle: const Text('ملف Excel مع تنسيق متقدم وملخص'),
                              trailing: ElevatedButton.icon(
                                onPressed: _filteredTransactions.isEmpty ? null : _exportExcel,
                                icon: const Icon(Icons.download),
                                label: const Text('تصدير'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Empty State
                    if (_filteredTransactions.isEmpty && !_isLoading) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.file_download_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد بيانات للتصدير',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تأكد من إضافة معاملات أو تعديل الفلاتر',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر نوع المعاملة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('جميع الأنواع'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text(TransactionTypes.income),
                leading: Radio<String?>(
                  value: TransactionTypes.income,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text(TransactionTypes.expense),
                leading: Radio<String?>(
                  value: TransactionTypes.expense,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    final allCategories = [
      ...TransactionCategories.incomeCategories,
      ...TransactionCategories.expenseCategories,
    ].toSet().toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اختر الفئة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('جميع الفئات'),
                      leading: Radio<String?>(
                        value: null,
                        groupValue: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ...allCategories.map((category) => ListTile(
                      title: Text(category),
                      leading: Radio<String?>(
                        value: category,
                        groupValue: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}