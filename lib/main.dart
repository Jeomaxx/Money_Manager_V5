import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import your providers and services
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/main_navigation.dart';
import 'widgets/animated_balance_card.dart';
import 'widgets/animated_transaction_list.dart';
import 'models/transaction.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'مدير المصروفات الشخصية',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'), // Arabic
            Locale('en'), // English fallback
          ],
          locale: const Locale('ar'), // Default to Arabic
          home: const AuthWrapper(),
          routes: {
            '/home': (context) => MainNavigation(
              homeScreen: const MyHomePage(
                title: 'مدير المصروفات الشخصية',
                isEmbedded: true,
              ),
            ),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.teal,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'مدير المصروفات',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return MainNavigation(
            homeScreen: const MyHomePage(
              title: 'مدير المصروفات الشخصية',
              isEmbedded: true,
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.isEmbedded = false});

  final String title;
  final bool isEmbedded;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> 
    with TickerProviderStateMixin {
  bool _isLoading = true;
  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;
  List<Transaction> _transactions = [];
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppTheme.animationCurve,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Simulate loading data from local storage
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Load actual data using DatabaseHelper or HiveTransactionRepository
      // For now using sample data, but in production this should load from Hive
      setState(() {
        _balance = 15000.0;
        _income = 25000.0;
        _expenses = 10000.0;
        _transactions = _generateSampleTransactions();
        _isLoading = false;
      });
      
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Transaction> _generateSampleTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 1,
        amount: 500.0,
        type: TransactionTypes.expense,
        category: TransactionCategories.food,
        note: 'غداء في مطعم',
        date: now.subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: 2,
        amount: 25000.0,
        type: TransactionTypes.income,
        category: TransactionCategories.salary,
        note: 'راتب شهر ${now.month}',
        date: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 3,
        amount: 200.0,
        type: TransactionTypes.expense,
        category: TransactionCategories.transportation,
        note: 'مواصلات',
        date: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 4,
        amount: 1500.0,
        type: TransactionTypes.expense,
        category: TransactionCategories.bills,
        note: 'فاتورة كهرباء',
        date: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري تحميل البيانات...',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  ],
                ),
              )
            : SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 160,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: theme.primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return IconButton(
                              icon: Icon(
                                themeProvider.isDarkMode 
                                    ? Icons.light_mode 
                                    : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await AuthService().logout();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                        ),
                      ],
                    ),
                    
                    // Balance Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AnimatedBalanceCard(
                          balance: _balance,
                          income: _income,
                          expenses: _expenses,
                        ),
                      ).animate().fadeIn(
                        duration: AppTheme.animationMedium,
                        delay: const Duration(milliseconds: 200),
                      ),
                    ),
                    
                    // Recent Transactions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المعاملات الأخيرة',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to transactions screen
                              },
                              child: Text(
                                'عرض الكل',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(
                        duration: AppTheme.animationMedium,
                        delay: const Duration(milliseconds: 400),
                      ),
                    ),
                    
                    // Transaction List
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedTransactionList(
                          transactions: _transactions.take(5).toList(),
                        ),
                      ).animate().fadeIn(
                        duration: AppTheme.animationMedium,
                        delay: const Duration(milliseconds: 600),
                      ),
                    ),
                    
                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}