import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  // Get port from environment variable, defaulting to 5000
  final port = int.parse(Platform.environment['PORT'] ?? '5000');
  
  // Initialize Gemini AI service
  final aiService = GeminiAIServer();
  
  // Create a handler for static files (serve from build/web directory)
  final staticHandler = createStaticHandler(
    'build/web',
    defaultDocument: 'index.html',
    listDirectories: false,
  );
  
  // Create AI API routes
  Handler apiRouter = (request) async {
    if (request.url.path.startsWith('api/')) {
      return await _handleApiRequest(request, aiService);
    }
    return Response.notFound('API endpoint not found');
  };
  
  // Create a proper SPA fallback handler for Flutter web
  Handler spaFallbackHandler = (request) {
    // For missing routes in a Flutter web app, serve index.html
    if (request.method == 'GET') {
      final acceptHeader = request.headers['accept'] ?? '';
      if (acceptHeader.contains('text/html')) {
        // Read and serve the actual Flutter web index.html
        final indexFile = File('build/web/index.html');
        if (indexFile.existsSync()) {
          return Response.ok(
            indexFile.readAsStringSync(),
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
      }
    }
    // Return 404 for non-HTML requests and missing assets
    return Response.notFound('Not Found');
  };
  
  // Create a cascade handler with API routes first
  final cascadeHandler = Cascade()
    .add(apiRouter)
    .add(staticHandler)
    .add(spaFallbackHandler)
    .handler;
  
  // Add CORS and basic middleware
  final handler = Pipeline()
    .addMiddleware(_corsHeaders)
    .addMiddleware(logRequests())
    .addHandler(cascadeHandler);
  
  // Start the server
  final server = await shelf_io.serve(
    handler,
    '0.0.0.0',
    port,
  );
  
  print('Server running on http://${server.address.host}:${server.port}');
  print('AI API endpoints available at /api/');
}

// CORS middleware for mobile app communication
Middleware _corsHeaders = (handler) {
  return (request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
    }
    
    final response = await handler(request);
    return response.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      ...response.headers,
    });
  };
};

// Handle API requests
Future<Response> _handleApiRequest(Request request, GeminiAIServer aiService) async {
  try {
    switch (request.url.path) {
      case 'api/parse-transaction':
        if (request.method != 'POST') {
          return Response(405, body: jsonEncode({'error': 'Method not allowed'}));
        }
        return await _handleParseTransaction(request, aiService);
        
      case 'api/analyze-finances':
        if (request.method != 'POST') {
          return Response(405, body: jsonEncode({'error': 'Method not allowed'}));
        }
        return await _handleAnalyzeFinances(request, aiService);
        
      case 'api/health':
        return Response.ok(jsonEncode({
          'status': 'healthy',
          'ai_available': aiService.isAvailable,
          'timestamp': DateTime.now().toIso8601String(),
        }), headers: {'content-type': 'application/json'});
        
      default:
        return Response.notFound(jsonEncode({'error': 'API endpoint not found'}));
    }
  } catch (e) {
    print('API Error: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Internal server error', 'message': e.toString()}),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Parse transaction text using Gemini AI
Future<Response> _handleParseTransaction(Request request, GeminiAIServer aiService) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final text = data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Text is required'}),
        headers: {'content-type': 'application/json'},
      );
    }
    
    final result = await aiService.parseTransactionText(text);
    
    return Response.ok(
      jsonEncode({
        'success': true,
        'result': {
          'type': result.type,
          'amount': result.amount,
          'category': result.category,
          'note': result.note,
          'confidence': result.confidence,
        }
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    print('Parse transaction error: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to parse transaction', 'message': e.toString()}),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Analyze finances using Gemini AI
Future<Response> _handleAnalyzeFinances(Request request, GeminiAIServer aiService) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final transactions = data['transactions'] as List<dynamic>?;
    final currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? 0.0;
    
    if (transactions == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Transactions data is required'}),
        headers: {'content-type': 'application/json'},
      );
    }
    
    final result = await aiService.analyzeFinancialData(transactions, currentBalance);
    
    return Response.ok(
      jsonEncode({
        'success': true,
        'result': {
          'overallHealth': result.overallHealth,
          'insights': result.insights,
          'recommendations': result.recommendations,
          'spendingPatterns': result.spendingPatterns,
          'budgetSuggestions': result.budgetSuggestions,
          'riskWarnings': result.riskWarnings,
        }
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    print('Analyze finances error: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to analyze finances', 'message': e.toString()}),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Server-side Gemini AI service
class GeminiAIServer {
  GenerativeModel? _model;
  GenerativeModel? _proModel;
  bool _isAvailable = false;

  GeminiAIServer() {
    _initializeModels();
  }

  void _initializeModels() {
    try {
      final apiKey = Platform.environment['GEMINI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        print('Warning: AI features disabled - GEMINI_API_KEY not available');
        return;
      }
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1,
        ),
      );
      
      _proModel = GenerativeModel(
        model: 'gemini-1.5-pro-latest',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3,
        ),
      );
      
      _isAvailable = true;
      print('✅ AI services initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize AI services: $e');
      _isAvailable = false;
    }
  }

  bool get isAvailable => _isAvailable;

  Future<ParsedTransactionResult> parseTransactionText(String input) async {
    if (!_isAvailable || _model == null) {
      throw Exception('AI services not available');
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

      String jsonStr = _cleanJsonResponse(response.text!);
      final jsonData = jsonDecode(jsonStr);
      
      return ParsedTransactionResult(
        type: jsonData['type'] ?? 'expense',
        amount: (jsonData['amount'] ?? 0).toDouble(),
        category: jsonData['category'] ?? 'أخرى',
        note: jsonData['note'],
        confidence: (jsonData['confidence'] ?? 0.5).toDouble(),
      );
      
    } catch (e) {
      print('Error parsing transaction with Gemini: $e');
      return ParsedTransactionResult(
        type: 'expense',
        amount: 0.0,
        category: 'أخرى',
        note: 'فشل في التحليل: $input',
        confidence: 0.0,
      );
    }
  }

  Future<FinancialAnalysisResult> analyzeFinancialData(
    List<dynamic> transactions,
    double currentBalance,
  ) async {
    if (!_isAvailable || _proModel == null) {
      throw Exception('AI services not available');
    }
    
    try {
      final summary = _prepareTransactionSummary(transactions, currentBalance);
      
      const prompt = '''
أنت مستشار مالي خبير. قم بتحليل البيانات المالية التالية وقدم نصائح مفيدة باللغة العربية.

البيانات المالية:
{FINANCIAL_DATA}

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

      final content = [Content.text(prompt.replaceAll('{FINANCIAL_DATA}', summary))];
      final response = await _proModel!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      String jsonStr = _cleanJsonResponse(response.text!);
      final jsonData = jsonDecode(jsonStr);
      
      return FinancialAnalysisResult(
        overallHealth: jsonData['overallHealth'] ?? 'متوسط',
        insights: List<String>.from(jsonData['insights'] ?? []),
        recommendations: List<String>.from(jsonData['recommendations'] ?? []),
        spendingPatterns: List<String>.from(jsonData['spendingPatterns'] ?? []),
        budgetSuggestions: jsonData['budgetSuggestions'] ?? '',
        riskWarnings: List<String>.from(jsonData['riskWarnings'] ?? []),
      );
      
    } catch (e) {
      print('Error analyzing financial data with Gemini: $e');
      return FinancialAnalysisResult(
        overallHealth: 'غير محدد',
        insights: ['حدث خطأ في تحليل البيانات المالية'],
        recommendations: ['يرجى المحاولة مرة أخرى لاحقاً'],
        spendingPatterns: [],
        budgetSuggestions: 'غير متاح حالياً',
        riskWarnings: [],
      );
    }
  }

  String _cleanJsonResponse(String response) {
    String jsonStr = response.trim();
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    }
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    return jsonStr.trim();
  }

  String _prepareTransactionSummary(List<dynamic> transactions, double currentBalance) {
    if (transactions.isEmpty) {
      return 'لا توجد معاملات\nالرصيد الحالي: ${currentBalance.toStringAsFixed(2)} جنيه';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    for (var txn in transactions) {
      if (txn is Map<String, dynamic>) {
        final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
        final type = txn['type'] as String? ?? 'expense';
        final category = txn['category'] as String? ?? 'أخرى';
        
        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
        
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    final netIncome = totalIncome - totalExpense;
    
    String summary = '''
إجمالي المعاملات: ${transactions.length}
إجمالي الدخل: ${totalIncome.toStringAsFixed(2)} جنيه
إجمالي المصروفات: ${totalExpense.toStringAsFixed(2)} جنيه
صافي الدخل: ${netIncome.toStringAsFixed(2)} جنيه
الرصيد الحالي: ${currentBalance.toStringAsFixed(2)} جنيه

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

// Result classes
class ParsedTransactionResult {
  final String type;
  final double amount;
  final String category;
  final String? note;
  final double confidence;

  ParsedTransactionResult({
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.confidence,
  });
}

class FinancialAnalysisResult {
  final String overallHealth;
  final List<String> insights;
  final List<String> recommendations;
  final List<String> spendingPatterns;
  final String budgetSuggestions;
  final List<String> riskWarnings;

  FinancialAnalysisResult({
    required this.overallHealth,
    required this.insights,
    required this.recommendations,
    required this.spendingPatterns,
    required this.budgetSuggestions,
    required this.riskWarnings,
  });
}