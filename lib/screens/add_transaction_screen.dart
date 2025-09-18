import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:ui' as ui;
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/voice_transaction_parser.dart';
import '../services/ai_transaction_parser.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  
  String _selectedType = TransactionTypes.expense; // Default to expense
  String _selectedCategory = TransactionCategories.expenseCategories.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // Voice input related
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _voiceText = '';
  bool _showVoiceResults = false;

  @override
  void initState() {
    super.initState();
    _updateCategoryForType();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في التعرف على الصوت: ${errorNotification.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    
    setState(() {
      _speechAvailable = available;
    });
    
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('التعرف على الصوت غير متاح على هذا الجهاز'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _updateCategoryForType() {
    final categories = TransactionCategories.getCategoriesForType(_selectedType);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    
    setState(() {
      _isListening = true;
      _voiceText = '';
      _showVoiceResults = false;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
        });
      },
      localeId: 'ar_EG', // Egyptian Arabic
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      ),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    
    if (_voiceText.isNotEmpty) {
      _processVoiceInput(_voiceText);
    }
  }

  void _processVoiceInput(String voiceText) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('جاري تحليل النص باستخدام الذكاء الاصطناعي...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Use AI-enhanced parser
      final parsedTransaction = await AiTransactionParser.parseTransactionInput(voiceText);
      
      setState(() {
        _showVoiceResults = true;
        
        // Update form fields based on parsed data
        if (parsedTransaction.amount > 0) {
          _amountController.text = parsedTransaction.amount.toString();
        }
        
        _selectedType = parsedTransaction.type;
        _updateCategoryForType();
        
        final categories = TransactionCategories.getCategoriesForType(_selectedType);
        if (categories.contains(parsedTransaction.category)) {
          _selectedCategory = parsedTransaction.category;
        }
        
        if (parsedTransaction.note != null && parsedTransaction.note!.isNotEmpty) {
          _noteController.text = parsedTransaction.note!;
        }
      });

      // Show success message with confidence and method info
      String methodText = '';
      if (parsedTransaction.isAiParsed) {
        methodText = ' (ذكاء اصطناعي)';
      } else if (parsedTransaction.parsingMethod == 'rule-based') {
        methodText = ' (تحليل تقليدي)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parsedTransaction.isHighConfidence 
              ? 'تم تحليل الصوت بنجاح!$methodText تحقق من البيانات قبل الحفظ'
              : 'تم تحليل الصوت جزئياً.$methodText يرجى مراجعة البيانات',
          ),
          backgroundColor: parsedTransaction.isHighConfidence ? Colors.green : Colors.orange,
          action: SnackBarAction(
            label: 'إخفاء',
            onPressed: () {
              setState(() {
                _showVoiceResults = false;
              });
            },
          ),
        ),
      );
    } catch (e) {
      // Fallback to traditional parsing if AI fails
      final parsedTransaction = VoiceTransactionParser.parseVoiceInput(voiceText);
      
      setState(() {
        _showVoiceResults = true;
        
        if (parsedTransaction.amount != null) {
          _amountController.text = parsedTransaction.amount!.toString();
        }
        
        _selectedType = parsedTransaction.type ?? TransactionTypes.expense;
        _updateCategoryForType();
        
        if (parsedTransaction.category != null) {
          final categories = TransactionCategories.getCategoriesForType(_selectedType);
          if (categories.contains(parsedTransaction.category)) {
            _selectedCategory = parsedTransaction.category!;
          }
        }
        
        if (parsedTransaction.note != null && parsedTransaction.note!.isNotEmpty) {
          _noteController.text = parsedTransaction.note!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم استخدام التحليل التقليدي. يرجى مراجعة البيانات'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'إخفاء',
            onPressed: () {
              setState(() {
                _showVoiceResults = false;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      await _transactionService.addTransaction(
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedType == TransactionTypes.income
                  ? 'تم إضافة الدخل بنجاح'
                  : 'تم إضافة المصروف بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
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
          title: const Text('إضافة معاملة جديدة'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voice Input Section
                if (_speechAvailable) ...[
                  Card(
                    color: _isListening ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _isListening ? 'جاري الاستماع...' : 'إدخال صوتي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isListening ? Colors.red.shade700 : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isListening ? null : _startListening,
                                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                                label: Text(_isListening ? 'يستمع...' : 'ابدأ التسجيل'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isListening ? Colors.grey : Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              if (_isListening)
                                ElevatedButton.icon(
                                  onPressed: _stopListening,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('إيقاف'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          if (_voiceText.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'النص المسجل:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _voiceText,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_showVoiceResults) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, 
                                       color: Colors.green.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'تم تحديث النموذج بناءً على الصوت',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showVoiceResults = false;
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Transaction Type Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نوع المعاملة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: TransactionTypes.income,
                                groupValue: _selectedType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                    _updateCategoryForType();
                                  });
                                },
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(TransactionTypes.income),
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: TransactionTypes.expense,
                                groupValue: _selectedType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                    _updateCategoryForType();
                                  });
                                },
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_down,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(TransactionTypes.expense),
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المبلغ (ج.م)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'أدخل المبلغ',
                            prefixIcon: Icon(Icons.monetization_on),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال المبلغ';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'يرجى إدخال مبلغ صحيح';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الفئة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          items: TransactionCategories.getCategoriesForType(_selectedType)
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التاريخ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy', 'ar').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note Input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ملاحظة (اختيارية)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'أضف ملاحظة...',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('حفظ المعاملة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}