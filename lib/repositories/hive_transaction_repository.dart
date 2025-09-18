import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  static const String _boxName = 'transactions';
  static const String _nextIdKey = 'nextId';
  late Box _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  int _getNextId() {
    final currentId = (_box.get(_nextIdKey) ?? 1) as int;
    _box.put(_nextIdKey, currentId + 1);
    return currentId;
  }

  @override
  Future<int> addTransaction(Transaction transaction) async {
    final id = _getNextId();
    final transactionWithId = transaction.copyWith(id: id);
    await _box.put(id, transactionWithId.toMap());
    return id;
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final List<Transaction> transactions = [];
    for (final key in _box.keys) {
      if (key != _nextIdKey && key is int) {
        final map = _box.get(key) as Map<dynamic, dynamic>;
        final convertedMap = Map<String, dynamic>.from(map);
        transactions.add(Transaction.fromMap(convertedMap));
      }
    }
    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  @override
  Future<List<Transaction>> getTransactionsByType(String type) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => t.type == type).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => 
      !t.date.isBefore(startDate) && !t.date.isAfter(endDate)
    ).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.where((t) => t.category == category).toList();
  }

  @override
  Future<int> updateTransaction(Transaction transaction) async {
    if (transaction.id != null) {
      await _box.put(transaction.id!, transaction.toMap());
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    await _box.delete(id);
    return 1;
  }

  @override
  Future<double> getTotalBalance() async {
    final allTransactions = await getAllTransactions();
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    
    for (final transaction in allTransactions) {
      if (transaction.type == TransactionTypes.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == TransactionTypes.expense) {
        totalExpenses += transaction.amount;
      }
    }
    
    return totalIncome - totalExpenses;
  }

  @override
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final monthlyTransactions = await getTransactionsByMonth(year, month);
    double monthlyIncome = 0.0;
    double monthlyExpenses = 0.0;
    
    for (final transaction in monthlyTransactions) {
      if (transaction.type == TransactionTypes.income) {
        monthlyIncome += transaction.amount;
      } else if (transaction.type == TransactionTypes.expense) {
        monthlyExpenses += transaction.amount;
      }
    }
    
    return {
      'income': monthlyIncome,
      'expenses': monthlyExpenses,
      'balance': monthlyIncome - monthlyExpenses,
    };
  }

  @override
  Future<Map<String, double>> getExpensesByCategory(int year, int month) async {
    final monthlyTransactions = await getTransactionsByMonth(year, month);
    final Map<String, double> expensesByCategory = {};
    
    for (final transaction in monthlyTransactions) {
      if (transaction.type == TransactionTypes.expense) {
        expensesByCategory[transaction.category] = 
          (expensesByCategory[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    
    return expensesByCategory;
  }

  @override
  Future<int> clearAllTransactions() async {
    // Clear all transactions but keep the nextId
    final nextId = _box.get(_nextIdKey) ?? 1;
    await _box.clear();
    await _box.put(_nextIdKey, nextId);
    return 1;
  }
}