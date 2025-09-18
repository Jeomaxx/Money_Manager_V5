import '../models/transaction.dart';
import 'voice_transaction_parser.dart';
import 'gemini_ai_service.dart';

/// Enhanced transaction parser that combines rule-based parsing with AI
class AiTransactionParser {
  static GeminiAiService? _geminiService;
  
  static GeminiAiService _getGeminiService() {
    _geminiService ??= GeminiAiService();
    return _geminiService!;
  }

  /// Parse transaction input using both rule-based and AI methods
  static Future<EnhancedParsedTransaction> parseTransactionInput(String input) async {
    // First try the rule-based parser (fast and reliable for known patterns)
    final ruleBasedResult = VoiceTransactionParser.parseVoiceInput(input);
    
    // If rule-based parsing is successful and confident, use it
    if (ruleBasedResult.isValid && ruleBasedResult.amount != null && ruleBasedResult.amount! > 0) {
      return EnhancedParsedTransaction(
        type: ruleBasedResult.type,
        amount: ruleBasedResult.amount!,
        category: ruleBasedResult.category ?? _getDefaultCategory(ruleBasedResult.type),
        note: ruleBasedResult.note,
        confidence: 0.9, // High confidence for rule-based parsing
        parsingMethod: 'rule-based',
        suggestions: [],
      );
    }

    // If rule-based parsing fails or is not confident, try AI parsing
    try {
      final geminiService = _getGeminiService();
      if (!geminiService.isAvailable) {
        // AI not available, return rule-based result with low confidence
        return EnhancedParsedTransaction(
          type: ruleBasedResult.type,
          amount: ruleBasedResult.amount ?? 0,
          category: ruleBasedResult.category ?? _getDefaultCategory(ruleBasedResult.type),
          note: 'تحليل تقليدي - الذكاء الاصطناعي غير متاح',
          confidence: 0.6,
          parsingMethod: 'rule-based-only',
          suggestions: [],
        );
      }
      
      final aiResult = await geminiService.parseTransactionText(input);
      
      if (aiResult.isValid) {
        return EnhancedParsedTransaction(
          type: aiResult.type,
          amount: aiResult.amount,
          category: aiResult.category,
          note: aiResult.note,
          confidence: aiResult.confidence,
          parsingMethod: 'ai',
          suggestions: [],
        );
      }
    } catch (e) {
      print('AI parsing failed: $e');
    }

    // If both methods fail, return a partial result with suggestions
    return EnhancedParsedTransaction(
      type: ruleBasedResult.type,
      amount: ruleBasedResult.amount ?? 0,
      category: ruleBasedResult.category ?? _getDefaultCategory(ruleBasedResult.type),
      note: input, // Keep original input as note
      confidence: 0.2, // Low confidence
      parsingMethod: 'fallback',
      suggestions: _generateBasicSuggestions(input),
    );
  }

  /// Generate transaction suggestions for autocomplete
  static Future<List<String>> generateSuggestions(
    String partialInput,
    List<Transaction> recentTransactions,
  ) async {
    if (partialInput.trim().isEmpty) {
      return _getCommonTransactionTemplates();
    }

    try {
      // Use AI to generate smart suggestions
      final geminiService = _getGeminiService();
      if (!geminiService.isAvailable) {
        return VoiceTransactionParser.getSuggestions(partialInput);
      }
      
      final suggestions = await geminiService.generateTransactionSuggestions(
        partialInput,
        recentTransactions,
      );
      
      if (suggestions.isNotEmpty) {
        return suggestions;
      }
    } catch (e) {
      print('Failed to generate AI suggestions: $e');
    }

    // Fallback to rule-based suggestions
    return VoiceTransactionParser.getSuggestions(partialInput);
  }

  /// Analyze financial data using AI
  static Future<FinancialInsights> analyzeFinancialData(
    List<Transaction> transactions,
    double currentBalance,
  ) async {
    try {
      final geminiService = _getGeminiService();
      if (!geminiService.isAvailable) {
        return FinancialInsights(
          overallHealth: 'غير محدد',
          insights: ['الذكاء الاصطناعي غير متاح حالياً'],
          recommendations: ['يمكنك مراجعة البيانات يدوياً'],
          spendingPatterns: [],
          budgetSuggestions: 'غير متاح',
          riskWarnings: [],
        );
      }
      
      return await geminiService.analyzeFinancialData(transactions, currentBalance);
    } catch (e) {
      print('Failed to analyze financial data: $e');
      return FinancialInsights(
        overallHealth: 'غير محدد',
        insights: ['حدث خطأ في تحليل البيانات'],
        recommendations: ['يرجى المحاولة مرة أخرى'],
        spendingPatterns: [],
        budgetSuggestions: 'غير متاح',
        riskWarnings: [],
      );
    }
  }

  static String _getDefaultCategory(String type) {
    if (type == TransactionTypes.income) {
      return 'أخرى';
    } else {
      return 'أخرى';
    }
  }

  static List<String> _generateBasicSuggestions(String input) {
    return [
      'أكل في مطعم بـ 100 جنيه',
      'مواصلات تاكسي بـ 50 جنيه', 
      'شراء قهوة بـ 25 جنيه',
      'فاتورة كهرباء 200 جنيه',
      'دخل راتب 5000 جنيه'
    ];
  }

  static List<String> _getCommonTransactionTemplates() {
    return [
      'اشتريت طعام بـ 100 جنيه',
      'دفعت فاتورة كهرباء 200 جنيه',
      'ركبت تاكسي بـ 50 جنيه',
      'استلمت راتب 5000 جنيه',
      'اشتريت قهوة بـ 25 جنيه',
      'دفعت إيجار 2000 جنيه',
      'ذهبت للدكتور 300 جنيه',
      'اشتريت ملابس بـ 500 جنيه',
      'شحنت رصيد موبايل 50 جنيه',
      'ذهبت للسينما 150 جنيه'
    ];
  }
}

/// Enhanced transaction parsing result with AI capabilities
class EnhancedParsedTransaction {
  final String type;
  final double amount;
  final String category;
  final String? note;
  final double confidence;
  final String parsingMethod;
  final List<String> suggestions;

  EnhancedParsedTransaction({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.confidence,
    required this.parsingMethod,
    required this.suggestions,
  });

  bool get isValid => amount > 0;
  bool get isHighConfidence => confidence > 0.7;
  bool get isAiParsed => parsingMethod == 'ai';

  @override
  String toString() {
    return 'EnhancedParsedTransaction(type: $type, amount: $amount, category: $category, note: $note, confidence: $confidence, method: $parsingMethod)';
  }
}