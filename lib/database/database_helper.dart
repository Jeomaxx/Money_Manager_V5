import 'dart:async';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date INTEGER NOT NULL
      )
    ''');
  }

  // Insert a new transaction
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC', // Newest first
    );
    
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Get transactions by type (Income or Expense)
  Future<List<Transaction>> getTransactionsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Get transactions for a specific month and year
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Update a transaction
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total balance (Income - Expenses)
  Future<double> getTotalBalance() async {
    final db = await database;
    
    // Get total income
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [TransactionTypes.income]
    );
    final totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Get total expenses
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [TransactionTypes.expense]
    );
    final totalExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    return totalIncome - totalExpenses;
  }

  // Get monthly summary for a specific month
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    // Get monthly income
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [TransactionTypes.income, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]
    );
    final monthlyIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Get monthly expenses
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [TransactionTypes.expense, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]
    );
    final monthlyExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'income': monthlyIncome,
      'expenses': monthlyExpenses,
      'balance': monthlyIncome - monthlyExpenses,
    };
  }

  // Get expense breakdown by category for charts
  Future<Map<String, double>> getExpensesByCategory(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ? GROUP BY category',
      [TransactionTypes.expense, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]
    );
    
    Map<String, double> expensesByCategory = {};
    for (var row in result) {
      expensesByCategory[row['category'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    
    return expensesByCategory;
  }

  // Clear all transactions (for settings/reset functionality)
  Future<int> clearAllTransactions() async {
    final db = await database;
    return await db.delete('transactions');
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}