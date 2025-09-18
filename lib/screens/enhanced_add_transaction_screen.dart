import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:ui' as ui;

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/voice_transaction_parser.dart';
import '../services/ai_transaction_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_form_field.dart';
import '../widgets/animated_button.dart';
import '../widgets/celebration_animation.dart';

class EnhancedAddTransactionScreen extends StatefulWidget {
  const EnhancedAddTransactionScreen({super.key});

  @override
  State<EnhancedAddTransactionScreen> createState() => _EnhancedAddTransactionScreenState();
}

class _EnhancedAddTransactionScreenState extends State<EnhancedAddTransactionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  
  String _selectedType = TransactionTypes.expense;
  String _selectedCategory = TransactionCategories.expenseCategories.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _showCelebration = false;
  
  // Voice input related
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _voiceText = '';
  bool _showVoiceResults = false;
  
  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _voiceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateCategoryForType();
    _initializeSpeech();
  }

  void _initializeAnimations() {
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _voiceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: AppTheme.animationCurve,
    ));

    // Start page entrance animation
    _pageController.forward();
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
          _voiceController.reverse();
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
        _voiceController.reverse();
        HapticFeedback.heavyImpact();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في التعرف على الصوت: ${errorNotification.errorMsg}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
    
    setState(() {
      _speechAvailable = available;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    _voiceController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _updateCategoryForType() {
    final categories = TransactionCategories.getCategoriesForType(_selectedType);
    if (!categories.contains(_selectedCategory)) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primarySeed,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _voiceText = '';
      _showVoiceResults = false;
    });

    _voiceController.forward();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
        });
      },
      localeId: 'ar_EG',
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
    _voiceController.reverse();
    
    if (_voiceText.isNotEmpty) {
      _processVoiceInput(_voiceText);
    }
  }

  void _processVoiceInput(String voiceText) async {
    // Voice processing logic with enhanced feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      _showVoiceResults = true;
    });

    try {
      // Parse voice input for transaction data using static method
      final result = VoiceTransactionParser.parseVoiceInput(voiceText);
      
      if (result.isValid) {
        // Auto-fill form with voice input results
        setState(() {
          if (result.amount != null && result.amount! > 0) {
            _amountController.text = result.amount.toString();
          }
          
          if (result.type.isNotEmpty) {
            _selectedType = result.type == 'دخل' || result.type == 'income' 
                ? TransactionTypes.income 
                : TransactionTypes.expense;
            _updateCategoryForType();
          }
          
          if (result.category != null && result.category!.isNotEmpty) {
            final categories = TransactionCategories.getCategoriesForType(_selectedType);
            if (categories.contains(result.category!)) {
              _selectedCategory = result.category!;
            }
          }
          
          if (result.note != null && result.note!.isNotEmpty) {
            _noteController.text = result.note!;
          }
        });
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التعرف على: $voiceText'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error if voice input couldn't be parsed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لم أتمكن من فهم المدخل الصوتي، حاول مرة أخرى'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة الصوت: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final amount = double.parse(_amountController.text);
      await _transactionService.addTransaction(
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
      );

      // Success feedback
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _showCelebration = true;
      });

      HapticFeedback.heavyImpact(); // Strong success feedback

      // Show celebration for 2 seconds then navigate back
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'إغلاق',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع المعاملة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  type: TransactionTypes.income,
                  icon: Icons.trending_up,
                  color: AppTheme.incomeColor,
                  isSelected: _selectedType == TransactionTypes.income,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildTypeOption(
                  type: TransactionTypes.expense,
                  icon: Icons.trending_down,
                  color: AppTheme.expenseColor,
                  isSelected: _selectedType == TransactionTypes.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedType = type;
          _updateCategoryForType();
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.animationMedium,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [color, color.withOpacity(0.8)]
                : [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 32,
            )
                .animate(target: isSelected ? 1.0 : 0.0)
                .scaleXY(begin: 1.0, end: 1.2, duration: 200.ms)
                .rotate(begin: 0, end: 0.05, duration: 200.ms),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              type,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفئة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.category_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            items: TransactionCategories.getCategoriesForType(_selectedType)
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('EEEE، dd MMMM yyyy', 'ar');
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التاريخ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      dateFormat.format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة معاملة جديدة'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
        ),
        body: Stack(
          children: [
            // Main content
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: AnimationLimiter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 400),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                // Transaction Type Selector
                                _buildTypeSelector(),
                                
                                const SizedBox(height: AppTheme.spacingL),
                                
                                // Amount Input
                                AnimatedFormField(
                                  controller: _amountController,
                                  label: 'المبلغ',
                                  hintText: 'أدخل المبلغ بالجنيه المصري',
                                  prefixIcon: Icons.monetization_on_outlined,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
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
                                
                                const SizedBox(height: AppTheme.spacingL),
                                
                                // Category Dropdown
                                _buildCategoryDropdown(),
                                
                                const SizedBox(height: AppTheme.spacingL),
                                
                                // Date Selector
                                _buildDateSelector(),
                                
                                const SizedBox(height: AppTheme.spacingL),
                                
                                // Note Input
                                AnimatedFormField(
                                  controller: _noteController,
                                  label: 'ملاحظة (اختيارية)',
                                  hintText: 'أضف تفاصيل إضافية...',
                                  prefixIcon: Icons.note_outlined,
                                  maxLines: 3,
                                ),
                                
                                const SizedBox(height: AppTheme.spacingXxl),
                                
                                // Save Button
                                AnimatedButton(
                                  onPressed: _isLoading ? null : _saveTransaction,
                                  text: 'حفظ المعاملة',
                                  icon: Icons.save_outlined,
                                  isLoading: _isLoading,
                                  isSuccess: _isSuccess,
                                  width: double.infinity,
                                ),
                                
                                const SizedBox(height: AppTheme.spacingXxl),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Celebration Animation Overlay
            SuccessCelebration(
              show: _showCelebration,
              message: _selectedType == TransactionTypes.income
                  ? 'تم إضافة الدخل بنجاح! 🎉'
                  : 'تم إضافة المصروف بنجاح! ✅',
              onComplete: () {
                setState(() {
                  _showCelebration = false;
                });
              },
            ),
          ],
        ),
        // Voice Input FAB
        floatingActionButton: _speechAvailable ? FloatingActionButton(
          onPressed: _isListening ? _stopListening : _startListening,
          backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isListening
                ? const Icon(Icons.mic, key: ValueKey('listening'))
                : const Icon(Icons.mic_none, key: ValueKey('not_listening')),
          ),
        ).animate(target: _speechAvailable ? 1.0 : 0.0)
          .scaleXY(begin: 0.0, end: 1.0, duration: 400.ms)
          .fadeIn(duration: 300.ms) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}