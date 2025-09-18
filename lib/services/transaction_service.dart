import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/hive_transaction_repository.dart';
import '../repositories/sqlite_transaction_repository.dart';

class TransactionService {
  late final TransactionRepository _repository;
  
  TransactionService() {
    if (kIsWeb) {
      _repository = HiveTransactionRepository();
    } else {
      _repository = SqliteTransactionRepository();
    }
  }
  
  Future<void> init() async {
    if (kIsWeb && _repository is HiveTransactionRepository) {
      await (_repository as HiveTransactionRepository).init();
    }
  }

  // Add a new transaction
  Future<int> addTransaction({
    required double amount,
    required String type,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final transaction = Transaction(
      amount: amount,
      type: type,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
    );
    
    return await _repository.addTransaction(transaction);
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    return await _repository.getAllTransactions();
  }

  // Get current balance
  Future<double> getCurrentBalance() async {
    return await _repository.getTotalBalance();
  }

  // Get transactions for current month
  Future<List<Transaction>> getCurrentMonthTransactions() async {
    final now = DateTime.now();
    return await _repository.getTransactionsByMonth(now.year, now.month);
  }

  // Get monthly summary for current month
  Future<Map<String, double>> getCurrentMonthlySummary() async {
    final now = DateTime.now();
    return await _repository.getMonthlySummary(now.year, now.month);
  }

  // Get expense breakdown by category for current month
  Future<Map<String, double>> getCurrentMonthExpensesByCategory() async {
    final now = DateTime.now();
    return await _repository.getExpensesByCategory(now.year, now.month);
  }

  // Update a transaction
  Future<int> updateTransaction(Transaction transaction) async {
    return await _repository.updateTransaction(transaction);
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    return await _repository.deleteTransaction(id);
  }

  // Add sample data for testing
  Future<void> addSampleData() async {
    // Add some sample income transactions
    await addTransaction(
      amount: 5000.0,
      type: TransactionTypes.income,
      category: 'راتب',
      note: 'راتب شهر نوفمبر',
      date: DateTime.now().subtract(const Duration(days: 30)),
    );

    await addTransaction(
      amount: 1000.0,
      type: TransactionTypes.income,
      category: 'مكافأة',
      note: 'مكافأة نهاية العام',
      date: DateTime.now().subtract(const Duration(days: 15)),
    );

    // Add some sample expense transactions
    await addTransaction(
      amount: 500.0,
      type: TransactionTypes.expense,
      category: 'طعام',
      note: 'تسوق البقالة',
      date: DateTime.now().subtract(const Duration(days: 5)),
    );

    await addTransaction(
      amount: 300.0,
      type: TransactionTypes.expense,
      category: 'مواصلات',
      note: 'بنزين السيارة',
      date: DateTime.now().subtract(const Duration(days: 3)),
    );

    await addTransaction(
      amount: 200.0,
      type: TransactionTypes.expense,
      category: 'ترفيه',
      note: 'مشاهدة فيلم',
      date: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  // Clear all data (for reset functionality)
  Future<int> clearAllData() async {
    return await _repository.clearAllTransactions();
  }
}