import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/transaction_service.dart';
import 'services/auth_service.dart';
import 'models/transaction.dart';
import 'widgets/transaction_list_item.dart';
import 'widgets/animated_balance_card.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/export_screen.dart';
import 'screens/import_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/main_navigation.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// Authentication Wrapper to check login status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      return MainNavigation(
        homeScreen: const MyHomePage(
          title: 'مدير المصروفات الشخصية',
          isEmbedded: true,
        ),
      );
    } else {
      return const LoginScreen();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'مدير المصروفات', // Arabic title
          debugShowCheckedModeBanner: false,
          
          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Arabic RTL support configuration
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
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key, 
    required this.title,
    this.isEmbedded = false,
  });

  final String title;
  final bool isEmbedded;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  
  late AnimationController _fabAnimationController;
  late AnimationController _balanceAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _balanceAnimation;
  late Animation<double> _loadingRotationAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _balanceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _loadingRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));
    
    _initializeAndLoadData();
    
    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
        _balanceAnimationController.forward();
      }
    });
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // Start loading animation
      _loadingAnimationController.repeat();
      await _transactionService.init();
      await _loadData();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _loadingAnimationController.stop();
      print('Error initializing service: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final balance = await _transactionService.getCurrentBalance();
      final transactions = await _transactionService.getAllTransactions();
      setState(() {
        _balance = balance;
        _transactions = transactions;
        _isLoading = false;
      });
      _loadingAnimationController.stop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _loadingAnimationController.stop();
      print('Error loading data: $e');
    }
  }

  Future<void> _addSampleData() async {
    try {
      await _transactionService.addSampleData();
      _loadData(); // Refresh data after adding sample data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة بيانات تجريبية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إضافة البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _balanceAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedFAB({
    required IconData icon,
    required IconData activeIcon,
    required Color backgroundColor,
    required String tooltip,
    required String heroTag,
    required VoidCallback onPressed,
    double size = 56,
    double iconSize = 24,
  }) {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: FloatingActionButton(
              onPressed: onPressed,
              tooltip: tooltip,
              heroTag: heroTag,
              backgroundColor: backgroundColor,
              elevation: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: iconSize,
                  key: ValueKey(icon),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return _isLoading
        ? _buildLoadingState()
        : RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.teal,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Animated Balance Summary Card
                      AnimatedBuilder(
                        animation: _balanceAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _balanceAnimation.value,
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal.shade400, Colors.teal.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.shade200.withOpacity(0.6),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'الرصيد الحالي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: _balance),
                                duration: const Duration(milliseconds: 1000),
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.toStringAsFixed(2)} ج.م',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildBalanceInfo(
                                    'إجمالي الدخل',
                                    '0.00 ج.م',
                                    Icons.arrow_upward_rounded,
                                    Colors.green.shade300,
                                  ),
                                  Container(
                                    width: 2,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  _buildBalanceInfo(
                                    'إجمالي المصروفات',
                                    '0.00 ج.م',
                                    Icons.arrow_downward_rounded,
                                    Colors.red.shade300,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Transactions Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'المعاملات الأخيرة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_transactions.length} معاملة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // Transactions List
                _transactions.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد معاملات بعد',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابدأ بإضافة أول معاملة لك',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              if (widget.isEmbedded)
                                ElevatedButton.icon(
                                  onPressed: _addSampleData,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('إضافة بيانات تجريبية'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final transaction = _transactions[index];
                            return TransactionListItem(
                              transaction: transaction,
                              onTap: () {
                                // TODO: Navigate to transaction details/edit
                              },
                              onLongPress: () {
                                // TODO: Show delete/edit options
                              },
                            );
                          },
                          childCount: _transactions.length,
                        ),
                      ),
              ],
            );
  }

  @override
  Widget build(BuildContext context) {
    // When embedded in MainNavigation, return content only (no Scaffold/AppBar/FAB)
    if (widget.isEmbedded) {
      return _buildMainContent();
    }
    
    // When not embedded, return full Scaffold structure
    return Directionality(
      textDirection: TextDirection.rtl, // Force RTL layout
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          centerTitle: true,
        ),
        drawer: _buildNavigationDrawer(),
        body: _buildMainContent(),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildAnimatedFAB(
              icon: Icons.file_download_outlined,
              activeIcon: Icons.file_download,
              backgroundColor: Colors.teal,
              tooltip: 'تصدير البيانات',
              heroTag: "export",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAnimatedFAB(
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights,
              backgroundColor: Colors.purple,
              tooltip: 'التحليل الشهري',
              heroTag: "analysis",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AnalysisScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAnimatedFAB(
              icon: Icons.scatter_plot_outlined,
              activeIcon: Icons.scatter_plot,
              backgroundColor: Colors.orange,
              tooltip: 'إضافة بيانات تجريبية',
              heroTag: "sample_data",
              onPressed: _addSampleData,
            ),
            const SizedBox(height: 12),
            _buildAnimatedFAB(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              backgroundColor: Theme.of(context).primaryColor,
              tooltip: 'إضافة معاملة',
              heroTag: "add_transaction",
              size: 60,
              iconSize: 30,
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading icon with repeating rotation
          AnimatedBuilder(
            animation: _loadingRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingRotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        Colors.teal.shade300,
                        Colors.teal.shade600,
                        Colors.teal.shade300,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Loading text with fade animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'جاري تحميل البيانات...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 200)),
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(value * 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(String title, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.teal,
    bool isSelected = false,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (delay * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 100, 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? iconColor.withOpacity(0.1) : Colors.transparent,
              ),
              child: ListTile(
                leading: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + (delay * 100)),
                  curve: Curves.elasticOut,
                  builder: (context, iconValue, child) {
                    return Transform.scale(
                      scale: iconValue,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                    color: isSelected ? iconColor : Colors.black87,
                  ),
                ),
                onTap: onTap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, iconValue, child) {
                            return Transform.rotate(
                              angle: (1 - iconValue) * 0.5,
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 48 * iconValue,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 600),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * value,
                            fontWeight: FontWeight.bold,
                          ),
                          child: const Text('مدير المصروفات'),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 800),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9 * value),
                            fontSize: 16 * value,
                          ),
                          child: const Text('إدارة مالية ذكية'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            
            // Home
            _buildAnimatedMenuItem(
              icon: Icons.home_outlined,
              title: 'الصفحة الرئيسية',
              iconColor: Colors.teal,
              isSelected: true,
              delay: 0,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.add_circle_outline,
              title: 'إضافة معاملة',
              iconColor: Colors.blue,
              delay: 1,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.insights_outlined,
              title: 'التحليل الشهري',
              iconColor: Colors.purple,
              delay: 2,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AnalysisScreen(),
                  ),
                );
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Divider(thickness: 1),
            ),
            
            // Section Header
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'إدارة البيانات',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.upload_file_outlined,
              title: 'استيراد البيانات',
              iconColor: Colors.green,
              delay: 3,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const ImportScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.download_outlined,
              title: 'تصدير البيانات',
              iconColor: Colors.orange,
              delay: 4,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExportScreen(),
                  ),
                );
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Divider(thickness: 1),
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.settings_outlined,
              title: 'الإعدادات',
              iconColor: Colors.grey,
              delay: 5,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            
            _buildAnimatedMenuItem(
              icon: Icons.help_outline,
              title: 'المساعدة',
              iconColor: Colors.indigo,
              delay: 6,
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
            
            const SizedBox(height: 20),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2024 مدير المصروفات',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('المساعدة السريعة'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏠 الصفحة الرئيسية: عرض الرصيد والمعاملات'),
                SizedBox(height: 8),
                Text('➕ إضافة معاملة: إضافة دخل أو مصروف جديد'),
                SizedBox(height: 8),
                Text('📊 التحليل الشهري: عرض الإحصائيات والرسوم البيانية'),
                SizedBox(height: 8),
                Text('📤 تصدير البيانات: حفظ البيانات كملف CSV أو Excel'),
                SizedBox(height: 8),
                Text('📥 استيراد البيانات: رفع ملف CSV للاستيراد'),
                SizedBox(height: 8),
                Text('⚙️ الإعدادات: إدارة التطبيق والبيانات'),
                SizedBox(height: 12),
                Text(
                  'نصيحة: يمكنك استخدام الإدخال الصوتي بالضغط على زر الميكروفون عند إضافة معاملة!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فهمت'),
            ),
          ],
        ),
      ),
    );
  }
}
