import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<int> addTransaction(Transaction transaction);
  Future<List<Transaction>> getAllTransactions();
  Future<List<Transaction>> getTransactionsByType(String type);
  Future<List<Transaction>> getTransactionsByMonth(int year, int month);
  Future<List<Transaction>> getTransactionsByCategory(String category);
  Future<int> updateTransaction(Transaction transaction);
  Future<int> deleteTransaction(int id);
  Future<double> getTotalBalance();
  Future<Map<String, double>> getMonthlySummary(int year, int month);
  Future<Map<String, double>> getExpensesByCategory(int year, int month);
  Future<int> clearAllTransactions();
}