import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';

class GeminiAiService {
  static const String _missingKeyMessage = 'AI features are temporarily unavailable';
  
  GenerativeModel? _model;
  GenerativeModel? _proModel;
  bool _isAvailable = false;

  GeminiAiService() {
    _initializeModels();
  }

  void _initializeModels() {
    try {
      // Check if API key is available - this should come from server-side in production
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      
      if (apiKey.isEmpty) {
        print('Warning: AI features disabled - API key not available');
        return;
      }
      
      // Initialize models with stable versions
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Low temperature for consistent parsing
        ),
      );
      
      _proModel = GenerativeModel(
        model: 'gemini-1.5-pro-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3, // Slightly higher for creative insights
        ),
      );
      
      _isAvailable = true;
      print('AI services initialized successfully');
    } catch (e) {
      print('Failed to initialize AI services: $e');
      _isAvailable = false;
    }
  }

  bool get isAvailable => _isAvailable;

  /// Parse natural language transaction input in Arabic or English
  /// Example: "اشتريت قهوة بـ 25 جنيه" or "bought coffee for 25 EGP"
  Future<ParsedTransactionAI> parseTransactionText(String input) async {
    if (!_isAvailable || _model == null) {
      throw Exception(_missingKeyMessage);
    }
    
    try {
      const prompt = '''
أنت مساعد ذكي لتحليل المعاملات المالية باللغة العربية والإنجليزية.
قم بتحليل النص التالي واستخراج معلومات المعاملة المالية:

النص: "{INPUT_TEXT}"

يجب أن تعيد JSON صحيح بالشكل التالي:
{
  "type": "income" أو "expense",
  "amount": رقم المبلغ,
  "category": الفئة المناسبة,
  "note": ملاحظة مختصرة,
  "confidence": نسبة الثقة من 0 إلى 1
}

فئات الدخل المتاحة: ["راتب", "مكافأة", "استثمار", "هدية", "بيع", "عمل إضافي", "أخرى"]
فئات المصروفات المتاحة: ["طعام", "مواصلات", "سكن", "فواتير", "صحة", "تسوق", "ملابس", "ترفيه", "تعليم", "أخرى"]

ملاحظات مهمة:
- استخدم "income" للدخل و "expense" للمصروفات
- اختر الفئة الأنسب من القائمة المتاحة
- إذا لم تجد فئة مناسبة، استخدم "أخرى"
- العملة المفترضة هي الجنيه المصري
- إذا لم يكن النص واضحاً، ضع confidence أقل من 0.7
''';

      final content = [Content.text(prompt.replaceAll('{INPUT_TEXT}', input))];
      final response = await _model!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Clean the response to extract JSON
      String jsonStr = response.text!.trim();
      
      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      final jsonData = json.decode(jsonStr.trim());
      
      return ParsedTransactionAI(
        type: jsonData['type'] ?? 'expense',
        amount: (jsonData['amount'] ?? 0).toDouble(),
        category: jsonData['category'] ?? 'أخرى',
        note: jsonData['note'],
        confidence: (jsonData['confidence'] ?? 0.5).toDouble(),
      );
      
    } catch (e) {
      print('Error parsing transaction with Gemini: $e');
      return ParsedTransactionAI(
        type: 'expense',
        amount: 0.0,
        category: 'أخرى',
        note: 'فشل في التحليل: $input',
        confidence: 0.0,
      );
    }
  }

  /// Analyze financial data and provide insights
  Future<FinancialInsights> analyzeFinancialData(
    List<Transaction> transactions,
    double currentBalance,
  ) async {
    if (!_isAvailable || _proModel == null) {
      throw Exception(_missingKeyMessage);
    }
    
    try {
      // Prepare transaction summary for analysis
      final summary = _prepareTransactionSummary(transactions);
      
      const prompt = '''
أنت مستشار مالي خبير. قم بتحليل البيانات المالية التالية وقدم نصائح مفيدة باللغة العربية.

البيانات المالية:
{FINANCIAL_DATA}

الرصيد الحالي: {CURRENT_BALANCE} جنيه مصري

يجب أن تعيد JSON صحيح بالشكل التالي:
{
  "overallHealth": "ممتاز" أو "جيد" أو "متوسط" أو "ضعيف",
  "insights": [
    "نصيحة 1",
    "نصيحة 2",
    "نصيحة 3"
  ],
  "recommendations": [
    "توصية 1",
    "توصية 2"
  ],
  "spendingPatterns": [
    "نمط الإنفاق 1",
    "نمط الإنفاق 2"
  ],
  "budgetSuggestions": "اقتراحات الميزانية",
  "riskWarnings": [
    "تحذير 1 (إن وجد)"
  ]
}

تأكد من:
- تقديم نصائح عملية ومفيدة
- التركيز على أنماط الإنفاق والدخل
- تقديم تحذيرات للمخاطر المالية إن وجدت
- اقتراح طرق لتوفير المال وتحسين الوضع المالي
''';

      final content = [Content.text(
        prompt
            .replaceAll('{FINANCIAL_DATA}', summary)
            .replaceAll('{CURRENT_BALANCE}', currentBalance.toStringAsFixed(2))
      )];
      
      final response = await _proModel!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Clean and parse JSON response
      String jsonStr = response.text!.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      final jsonData = json.decode(jsonStr.trim());
      
      return FinancialInsights(
        overallHealth: jsonData['overallHealth'] ?? 'متوسط',
        insights: List<String>.from(jsonData['insights'] ?? []),
        recommendations: List<String>.from(jsonData['recommendations'] ?? []),
        spendingPatterns: List<String>.from(jsonData['spendingPatterns'] ?? []),
        budgetSuggestions: jsonData['budgetSuggestions'] ?? '',
        riskWarnings: List<String>.from(jsonData['riskWarnings'] ?? []),
      );
      
    } catch (e) {
      print('Error analyzing financial data with Gemini: $e');
      return FinancialInsights(
        overallHealth: 'غير محدد',
        insights: ['حدث خطأ في تحليل البيانات المالية'],
        recommendations: ['يرجى المحاولة مرة أخرى لاحقاً'],
        spendingPatterns: [],
        budgetSuggestions: 'غير متاح حالياً',
        riskWarnings: [],
      );
    }
  }

  /// Generate smart transaction suggestions based on context
  Future<List<String>> generateTransactionSuggestions(
    String partialInput,
    List<Transaction> recentTransactions,
  ) async {
    if (!_isAvailable || _model == null) {
      throw Exception(_missingKeyMessage);
    }
    
    try {
      // Get recent categories and patterns
      final recentCategories = recentTransactions
          .take(10)
          .map((t) => t.category)
          .toSet()
          .toList();
      
      const prompt = '''
بناءً على النص الجزئي التالي والمعاملات الحديثة، اقترح 5 معاملات محتملة:

النص الجزئي: "{PARTIAL_INPUT}"
الفئات الحديثة: {RECENT_CATEGORIES}

أعد قائمة JSON بـ 5 اقتراحات مناسبة:
{
  "suggestions": [
    "اقتراح 1",
    "اقتراح 2",
    "اقتراح 3",
    "اقتراح 4",
    "اقتراح 5"
  ]
}

تأكد من أن الاقتراحات:
- ذات صلة بالنص الجزئي
- مناسبة للاستخدام المحلي المصري
- تتضمن مبالغ مقترحة معقولة
- متنوعة في الفئات
''';

      final content = [Content.text(
        prompt
            .replaceAll('{PARTIAL_INPUT}', partialInput)
            .replaceAll('{RECENT_CATEGORIES}', recentCategories.join(', '))
      )];
      
      final response = await _model!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        return [];
      }

      String jsonStr = response.text!.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      final jsonData = json.decode(jsonStr.trim());
      return List<String>.from(jsonData['suggestions'] ?? []);
      
    } catch (e) {
      print('Error generating suggestions with Gemini: $e');
      return [];
    }
  }

  String _prepareTransactionSummary(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return 'لا توجد معاملات';
    }

    final now = DateTime.now();
    final thisMonth = transactions.where((t) => 
      t.date.year == now.year && t.date.month == now.month
    ).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    for (var transaction in thisMonth) {
      if (transaction.type == TransactionTypes.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
      
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    final netIncome = totalIncome - totalExpense;
    
    String summary = '''
إجمالي المعاملات هذا الشهر: ${thisMonth.length}
إجمالي الدخل: ${totalIncome.toStringAsFixed(2)} جنيه
إجمالي المصروفات: ${totalExpense.toStringAsFixed(2)} جنيه
صافي الدخل: ${netIncome.toStringAsFixed(2)} جنيه

توزيع المصروفات بالفئات:
''';

    categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          summary += '- ${entry.key}: ${entry.value.toStringAsFixed(2)} جنيه\n';
        });

    return summary;
  }
}

/// Parsed transaction result from AI
class ParsedTransactionAI {
  final String type;
  final double amount;
  final String category;
  final String? note;
  final double confidence;

  ParsedTransactionAI({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.confidence,
  });

  bool get isValid => amount > 0 && confidence > 0.5;

  @override
  String toString() {
    return 'ParsedTransactionAI(type: $type, amount: $amount, category: $category, note: $note, confidence: $confidence)';
  }
}

/// Financial insights from AI analysis
class FinancialInsights {
  final String overallHealth;
  final List<String> insights;
  final List<String> recommendations;
  final List<String> spendingPatterns;
  final String budgetSuggestions;
  final List<String> riskWarnings;

  FinancialInsights({
    required this.overallHealth,
    required this.insights,
    required this.recommendations,
    required this.spendingPatterns,
    required this.budgetSuggestions,
    required this.riskWarnings,
  });
}