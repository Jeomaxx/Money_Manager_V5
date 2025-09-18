import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class SqliteTransactionRepository implements TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Future<int> addTransaction(Transaction transaction) async {
    return await _databaseHelper.insertTransaction(transaction);
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    return await _databaseHelper.getAllTransactions();
  }

  @override
  Future<List<Transaction>> getTransactionsByType(String type) async {
    return await _databaseHelper.getTransactionsByType(type);
  }

  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    return await _databaseHelper.getTransactionsByMonth(year, month);
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    return await _databaseHelper.getTransactionsByCategory(category);
  }

  @override
  Future<int> updateTransaction(Transaction transaction) async {
    return await _databaseHelper.updateTransaction(transaction);
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return await _databaseHelper.deleteTransaction(id);
  }

  @override
  Future<double> getTotalBalance() async {
    return await _databaseHelper.getTotalBalance();
  }

  @override
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    return await _databaseHelper.getMonthlySummary(year, month);
  }

  @override
  Future<Map<String, double>> getExpensesByCategory(int year, int month) async {
    return await _databaseHelper.getExpensesByCategory(year, month);
  }

  @override
  Future<int> clearAllTransactions() async {
    return await _databaseHelper.clearAllTransactions();
  }
}