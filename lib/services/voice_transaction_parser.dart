import '../models/transaction.dart';

class VoiceTransactionParser {
  // Arabic number words mapping (expanded for Egyptian dialect)
  static const Map<String, int> _arabicNumbers = {
    // Single digits
    'واحد': 1,
    'اتنين': 2,
    'اثنين': 2,
    'تنين': 2,
    'ثلاثة': 3,
    'أربعة': 4,
    'أربعه': 4,
    'خمسة': 5,
    'خمسه': 5,
    'ستة': 6,
    'سته': 6,
    'سبعة': 7,
    'سبعه': 7,
    'ثمانية': 8,
    'ثمانيه': 8,
    'تسعة': 9,
    'تسعه': 9,
    // Tens
    'عشرة': 10,
    'عشره': 10,
    'عشر': 10,
    'عشرين': 20,
    'ثلاثين': 30,
    'أربعين': 40,
    'خمسين': 50,
    'ستين': 60,
    'سبعين': 70,
    'ثمانين': 80,
    'تسعين': 90,
    // Hundreds
    'مية': 100,
    'مائة': 100,
    'ميتين': 200,
    'مائتين': 200,
    'ثلاثمية': 300,
    'ثلاثمائة': 300,
    'أربعمية': 400,
    'أربعمائة': 400,
    'خمسمية': 500,
    'خمسمائة': 500,
    'خمسميه': 500,
    'ستمية': 600,
    'ستمائة': 600,
    'سبعمية': 700,
    'سبعمائة': 700,
    'ثمانمية': 800,
    'ثمانمائة': 800,
    'تسعمية': 900,
    'تسعمائة': 900,
    // Thousands
    'ألف': 1000,
    'الف': 1000,
    'الفين': 2000,
    'ألفين': 2000,
    'ثلاثة آلاف': 3000,
    'ثلاث آلاف': 3000,
    'أربعة آلاف': 4000,
    'أربع آلاف': 4000,
    'خمسة آلاف': 5000,
    'خمس آلاف': 5000,
    'ثلاثه آلاف': 3000,
    'أربعه آلاف': 4000,
    'خمسه آلاف': 5000,
  };

  // Transaction type keywords
  static const Map<String, String> _typeKeywords = {
    'دخل': TransactionTypes.income,
    'راتب': TransactionTypes.income,
    'مكافأة': TransactionTypes.income,
    'هدية': TransactionTypes.income,
    'بونس': TransactionTypes.income,
    'مصروف': TransactionTypes.expense,
    'مصاريف': TransactionTypes.expense,
    'شراء': TransactionTypes.expense,
    'اشتريت': TransactionTypes.expense,
    'دفعت': TransactionTypes.expense,
    'سددت': TransactionTypes.expense,
    'فاتورة': TransactionTypes.expense,
  };

  // Category keywords mapping - Fixed to match actual TransactionCategories
  static const Map<String, String> _categoryKeywords = {
    // Income categories
    'راتب': 'راتب',
    'مكافأة': 'مكافأة', 
    'مكافآت': 'مكافأة',
    'بونس': 'مكافأة',
    'استثمار': 'استثمار',
    'استثمارات': 'استثمار',
    'هدية': 'هدية',
    'هدايا': 'هدية',
    'بيع': 'بيع',
    'عمل': 'عمل إضافي',
    'شغل': 'عمل إضافي',
    
    // Expense categories
    'أكل': 'طعام',
    'طعام': 'طعام',
    'مطعم': 'طعام',
    'قهوة': 'طعام',
    'عشاء': 'طعام',
    'غداء': 'طعام',
    'فطار': 'طعام',
    'فطور': 'طعام',
    'مواصلات': 'مواصلات',
    'تاكسي': 'مواصلات',
    'أوبر': 'مواصلات',
    'باص': 'مواصلات',
    'اتوبيس': 'مواصلات',
    'مترو': 'مواصلات',
    'بنزين': 'مواصلات',
    'منزل': 'سكن',
    'بيت': 'سكن',
    'ايجار': 'سكن',
    'إيجار': 'سكن',
    'كهرباء': 'فواتير',
    'مياه': 'فواتير',
    'إنترنت': 'فواتير',
    'نت': 'فواتير',
    'تلفون': 'فواتير',
    'موبايل': 'فواتير',
    'صحة': 'صحة',
    'دكتور': 'صحة',
    'طبيب': 'صحة',
    'دواء': 'صحة',
    'أدوية': 'صحة',
    'صيدلية': 'صحة',
    'تسوق': 'تسوق',
    'شراء': 'تسوق',
    'ملابس': 'ملابس',
    'حذاء': 'ملابس',
    'جزمة': 'ملابس',
    'سينما': 'ترفيه',
    'فيلم': 'ترفيه',
    'لعبة': 'ترفيه',
    'كافيه': 'ترفيه',
    'مقهى': 'ترفيه',
    'تعليم': 'تعليم',
    'كتاب': 'تعليم',
    'كورس': 'تعليم',
    'جامعة': 'تعليم',
    'مدرسة': 'تعليم',
  };

  static ParsedTransaction parseVoiceInput(String voiceText) {
    String cleanText = _preprocessArabicText(voiceText);
    
    ParsedTransaction result = ParsedTransaction();
    
    // Parse transaction type
    result.type = _parseTransactionType(cleanText);
    
    // Parse amount
    result.amount = _parseAmount(cleanText);
    
    // Parse category
    result.category = _parseCategory(cleanText, result.type);
    
    // Parse note (remaining text after removing parsed parts)
    result.note = _parseNote(cleanText);
    
    return result;
  }

  // Preprocess Arabic text for better parsing
  static String _preprocessArabicText(String text) {
    String processed = text.toLowerCase().trim();
    
    // Normalize Arabic numerals to English
    processed = processed.replaceAll('١', '1');
    processed = processed.replaceAll('٢', '2');
    processed = processed.replaceAll('٣', '3');
    processed = processed.replaceAll('٤', '4');
    processed = processed.replaceAll('٥', '5');
    processed = processed.replaceAll('٦', '6');
    processed = processed.replaceAll('٧', '7');
    processed = processed.replaceAll('٨', '8');
    processed = processed.replaceAll('٩', '9');
    processed = processed.replaceAll('٠', '0');
    
    // Normalize common alternative spellings
    processed = processed.replaceAll('ى', 'ي');
    processed = processed.replaceAll('ة', 'ه');
    
    // Remove extra spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    
    return processed;
  }

  static String _parseTransactionType(String text) {
    for (String keyword in _typeKeywords.keys) {
      if (text.contains(keyword)) {
        return _typeKeywords[keyword]!;
      }
    }
    return TransactionTypes.expense; // Default to expense
  }

  static double? _parseAmount(String text) {
    // Try to find numeric amount first (including decimals)
    RegExp numberRegex = RegExp(r'\d+(\.\d+)?');
    Match? match = numberRegex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    
    // Try to parse Arabic number words (including compound numbers)
    double? amount = _parseArabicNumbers(text);
    if (amount != null) {
      return amount;
    }
    
    return null;
  }

  static double? _parseArabicNumbers(String text) {
    // Enhanced implementation for compound Arabic numbers
    
    // First try compound numbers with "و" (and)
    if (text.contains('و')) {
      double? compoundNumber = _parseCompoundArabicNumber(text);
      if (compoundNumber != null) {
        return compoundNumber;
      }
    }
    
    // Try direct matches for single numbers (sort by length desc to match longest first)
    List<String> sortedKeys = _arabicNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String numberWord in sortedKeys) {
      if (text.contains(numberWord)) {
        return _arabicNumbers[numberWord]!.toDouble();
      }
    }
    
    return null;
  }
  
  // Parse compound Arabic numbers like "خمسة وعشرين" (twenty-five)
  static double? _parseCompoundArabicNumber(String text) {
    List<String> parts = text.split('و'); // Split by "and"
    if (parts.length < 2) return null;
    
    double total = 0;
    int validPartsCount = 0;
    
    // Sort by length descending to match longest phrases first
    List<String> sortedKeys = _arabicNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String part in parts) {
      part = part.trim();
      bool foundInThisPart = false;
      
      for (String numberWord in sortedKeys) {
        if (part.contains(numberWord)) {
          total += _arabicNumbers[numberWord]!;
          validPartsCount++;
          foundInThisPart = true;
          break; // Only match the first (longest) number in each part
        }
      }
      
      // If a part doesn't contain any valid number, it's not a valid compound number
      if (!foundInThisPart) {
        return null;
      }
    }
    
    return validPartsCount >= 2 && total > 0 ? total : null;
  }

  static String _parseCategory(String text, String transactionType) {
    List<String> availableCategories = TransactionCategories.getCategoriesForType(transactionType);
    
    for (String keyword in _categoryKeywords.keys) {
      if (text.contains(keyword)) {
        String suggestedCategory = _categoryKeywords[keyword]!;
        if (availableCategories.contains(suggestedCategory)) {
          return suggestedCategory;
        }
      }
    }
    
    // Return first category as default
    return availableCategories.first;
  }

  static String? _parseNote(String text) {
    // Remove recognized keywords and numbers to create a note
    String note = text;
    
    // Remove type keywords (sort by length desc to avoid partial matches)
    List<String> sortedTypeKeywords = _typeKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (String keyword in sortedTypeKeywords) {
      note = note.replaceAll(keyword, ' ');
    }
    
    // Remove category keywords (sort by length desc to avoid partial matches)
    List<String> sortedCategoryKeywords = _categoryKeywords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (String keyword in sortedCategoryKeywords) {
      note = note.replaceAll(keyword, ' ');
    }
    
    // Remove Arabic number words (sort by length desc to avoid partial matches)
    List<String> sortedNumberWords = _arabicNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (String numberWord in sortedNumberWords) {
      note = note.replaceAll(numberWord, ' ');
    }
    
    // Remove additional number-related words that might not be in the main map
    List<String> additionalNumberWords = [
      'خمسميه', 'خمسمیه', 'خمسمائه',
      'ميه', 'میه', 'مائه',
      'آلاف', 'الاف',
    ];
    for (String word in additionalNumberWords) {
      note = note.replaceAll(word, ' ');
    }
    
    // Remove numeric digits
    note = note.replaceAll(RegExp(r'\d+(\.\d+)?'), ' ');
    
    // Remove common currency and connector words
    note = note.replaceAll('جنيه', ' ');
    note = note.replaceAll('جنية', ' ');
    note = note.replaceAll('ج.م', ' ');
    note = note.replaceAll('و', ' '); // Remove "and" connector
    note = note.replaceAll('في', ' '); // Remove "in/at"
    note = note.replaceAll('من', ' '); // Remove "from"
    note = note.replaceAll('لـ', ' '); // Remove "for"
    
    // Clean up extra spaces and normalize
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return note.isEmpty ? null : note;
  }

  // Helper method to get suggested values for UI
  static List<String> getSuggestions(String partialText) {
    List<String> suggestions = [];
    String lowerText = partialText.toLowerCase();
    
    // Add type suggestions
    for (String keyword in _typeKeywords.keys) {
      if (keyword.contains(lowerText) || lowerText.contains(keyword)) {
        suggestions.add(keyword);
      }
    }
    
    // Add category suggestions
    for (String keyword in _categoryKeywords.keys) {
      if (keyword.contains(lowerText) || lowerText.contains(keyword)) {
        suggestions.add(keyword);
      }
    }
    
    return suggestions.take(5).toList(); // Limit to 5 suggestions
  }
}

class ParsedTransaction {
  String type = TransactionTypes.expense;
  double? amount;
  String? category;
  String? note;
  
  bool get isValid => amount != null && amount! > 0;
  
  @override
  String toString() {
    return 'ParsedTransaction(type: $type, amount: $amount, category: $category, note: $note)';
  }
}