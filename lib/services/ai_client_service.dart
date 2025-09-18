import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client service for communicating with server-side AI endpoints
class AIClientService {
  // Dynamic base URL that works on web and mobile
  static String get _baseUrl {
    // On web, use relative URLs
    if (identical(0, 0.0)) { // Web check
      return '/api';
    }
    // On mobile/desktop, use the current host
    return 'http://localhost:5000/api';
  }
  
  static const Duration _timeout = Duration(seconds: 10);

  /// Test connection to AI service
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ai_available'] == true;
      }
      return false;
    } catch (e) {
      print('AI service connection test failed: $e');
      return false;
    }
  }

  /// Parse transaction text using server-side Gemini AI
  Future<AITransactionResult?> parseTransaction(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/parse-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final result = data['result'];
          return AITransactionResult(
            type: result['type'] ?? 'expense',
            amount: (result['amount'] ?? 0).toDouble(),
            category: result['category'] ?? 'أخرى',
            note: result['note'],
            confidence: (result['confidence'] ?? 0.0).toDouble(),
          );
        }
      } else {
        print('AI parse transaction failed: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('AI parse transaction error: $e');
      return null;
    }
  }

  /// Analyze financial data using server-side Gemini AI
  Future<AIFinancialAnalysis?> analyzeFinances(
    List<Map<String, dynamic>> transactions,
    double currentBalance,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-finances'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactions': transactions,
          'currentBalance': currentBalance,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final result = data['result'];
          return AIFinancialAnalysis(
            overallHealth: result['overallHealth'] ?? 'متوسط',
            insights: List<String>.from(result['insights'] ?? []),
            recommendations: List<String>.from(result['recommendations'] ?? []),
            spendingPatterns: List<String>.from(result['spendingPatterns'] ?? []),
            budgetSuggestions: result['budgetSuggestions'] ?? '',
            riskWarnings: List<String>.from(result['riskWarnings'] ?? []),
          );
        }
      } else {
        print('AI analyze finances failed: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('AI analyze finances error: $e');
      return null;
    }
  }
}

/// AI transaction parsing result
class AITransactionResult {
  final String type;
  final double amount;
  final String category;
  final String? note;
  final double confidence;

  AITransactionResult({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.confidence,
  });

  bool get isValid => amount > 0 && confidence > 0.5;

  @override
  String toString() {
    return 'AITransactionResult(type: $type, amount: $amount, category: $category, confidence: $confidence)';
  }
}

/// AI financial analysis result
class AIFinancialAnalysis {
  final String overallHealth;
  final List<String> insights;
  final List<String> recommendations;
  final List<String> spendingPatterns;
  final String budgetSuggestions;
  final List<String> riskWarnings;

  AIFinancialAnalysis({
    required this.overallHealth,
    required this.insights,
    required this.recommendations,
    required this.spendingPatterns,
    required this.budgetSuggestions,
    required this.riskWarnings,
  });
}