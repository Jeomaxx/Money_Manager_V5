class Transaction {
  final int? id;
  final double amount;
  final String type; // 'دخل' (Income) or 'مصروف' (Expense)  
  final String category;
  final String? note;
  final DateTime date;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.note,
    required this.date,
  });

  // Convert Transaction to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'date': date.millisecondsSinceEpoch,
    };
  }

  // Create Transaction from Map (from database)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'].toDouble(),
      type: map['type'],
      category: map['category'],
      note: map['note'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }

  // Create a copy of Transaction with modified fields
  Transaction copyWith({
    int? id,
    double? amount,
    String? type,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $amount, type: $type, category: $category, note: $note, date: $date}';
  }
}

// Predefined categories for different transaction types
class TransactionCategories {
  // Income categories in Arabic
  static const List<String> incomeCategories = [
    'راتب', // Salary
    'مكافأة', // Bonus
    'استثمار', // Investment
    'هدية', // Gift
    'بيع', // Sale
    'عمل إضافي', // Extra work
    'أخرى', // Other
  ];

  // Expense categories in Arabic
  static const List<String> expenseCategories = [
    'طعام', // Food
    'مواصلات', // Transport
    'سكن', // Housing
    'ملابس', // Clothing
    'صحة', // Health
    'تعليم', // Education
    'ترفيه', // Entertainment
    'تسوق', // Shopping
    'فواتير', // Bills
    'أخرى', // Other
  ];

  static List<String> getCategoriesForType(String type) {
    return type == 'دخل' ? incomeCategories : expenseCategories;
  }
}

// Transaction types in Arabic
class TransactionTypes {
  static const String income = 'دخل';
  static const String expense = 'مصروف';
  
  static const List<String> allTypes = [income, expense];
}