import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Import your providers and services
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/main_navigation.dart';
import 'widgets/animated_balance_card.dart';
import 'widgets/animated_transaction_list.dart';
import 'models/transaction.dart';

void main() {
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
          home: MainNavigation(
            homeScreen: const MyHomePage(
              title: 'مدير المصروفات الشخصية',
              isEmbedded: true,
            ),
          ),
        );
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
    // Add haptic feedback for loading start
    HapticFeedback.lightImpact();
    
    setState(() {
      _isLoading = true;
    });

    // Simulate loading data with realistic delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock data for demonstration
    final mockTransactions = [
      Transaction(
        id: 1,
        amount: 500.0,
        type: TransactionTypes.income,
        category: 'راتب',
        note: 'راتب شهر سبتمبر',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 2,
        amount: 120.0,
        type: TransactionTypes.expense,
        category: 'طعام',
        note: 'عشاء مع الأصدقاء',
        date: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Transaction(
        id: 3,
        amount: 50.0,
        type: TransactionTypes.expense,
        category: 'مواصلات',
        note: 'تذاكر الحافلة',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    final totalIncome = mockTransactions
        .where((t) => t.type == TransactionTypes.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = mockTransactions
        .where((t) => t.type == TransactionTypes.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    setState(() {
      _transactions = mockTransactions;
      _income = totalIncome;
      _expenses = totalExpenses;
      _balance = _income - _expenses;
      _isLoading = false;
    });

    // Animate in the content after loading
    _slideController.forward();
    
    // Add haptic feedback for loading complete
    HapticFeedback.mediumImpact();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'جاري تحميل البيانات...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 800.ms)
              .fadeOut(delay: 800.ms, duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Main Balance Card
            AnimatedBalanceCard(
              balance: _balance,
              title: 'الرصيد الحالي',
              icon: Icons.account_balance_wallet,
              backgroundColor: AppTheme.getBalanceColor(context, _balance),
              isLoading: _isLoading,
            )
                .animate()
                .scaleXY(begin: 0.8, duration: 500.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Income and Expense Cards Row
            Row(
              children: [
                // Income Card
                Expanded(
                  child: AnimatedBalanceCard(
                    balance: _income,
                    title: 'إجمالي الدخل',
                    icon: Icons.trending_up,
                    backgroundColor: AppTheme.incomeColor,
                    isLoading: _isLoading,
                  )
                      .animate()
                      .slideX(begin: -0.3, duration: 400.ms, delay: 200.ms)
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                ),
                
                const SizedBox(width: AppTheme.spacingM),
                
                // Expenses Card
                Expanded(
                  child: AnimatedBalanceCard(
                    balance: _expenses,
                    title: 'إجمالي المصروفات',
                    icon: Icons.trending_down,
                    backgroundColor: AppTheme.expenseColor,
                    isLoading: _isLoading,
                  )
                      .animate()
                      .slideX(begin: 0.3, duration: 400.ms, delay: 400.ms)
                      .fadeIn(duration: 400.ms, delay: 400.ms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 400, // Fixed height to prevent layout issues
        child: AnimatedTransactionList(
          transactions: _transactions,
          onTransactionTap: (transaction) {
            // Navigate to transaction details
          },
          onTransactionDelete: (transaction) {
            // Handle transaction deletion
            setState(() {
              _transactions.removeWhere((t) => t.id == transaction.id);
            });
          },
          onShowAll: () {
            // Navigate to all transactions screen
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return _isLoading
        ? _buildLoadingState()
        : SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: _buildKPICards(),
                    ),
                  ),
                  _buildTransactionsList(),
                  // Add some bottom padding for the floating action button
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    // When embedded in MainNavigation, return content only
    if (widget.isEmbedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: _buildMainContent(),
      );
    }
    
    // When not embedded, return full Scaffold structure (fallback)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: _buildMainContent(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // TODO: Add new transaction
          },
          tooltip: 'إضافة معاملة',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}