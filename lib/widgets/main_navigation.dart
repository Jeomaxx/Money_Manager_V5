import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../screens/analysis_screen.dart';
import '../screens/enhanced_add_transaction_screen.dart';
import '../screens/export_screen.dart';
import '../screens/import_screen.dart';
import '../screens/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  final Widget homeScreen;

  const MainNavigation({
    super.key,
    required this.homeScreen,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: AppTheme.animationBounceCurve,
    ));
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: AppTheme.animationMedium,
        curve: AppTheme.animationCurve,
      );
    }
  }

  Widget _buildNavigationRail(ColorScheme colorScheme) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: const Text('الرئيسية'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: const Text('التحليل'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.add_circle_outline),
          selectedIcon: const Icon(Icons.add_circle),
          label: const Text('إضافة'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.import_export_outlined),
          selectedIcon: const Icon(Icons.import_export),
          label: const Text('البيانات'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: const Text('الإعدادات'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildAnimatedIcon(Icons.home_outlined, Icons.home, 0),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: _buildAnimatedIcon(Icons.analytics_outlined, Icons.analytics, 1),
            label: 'التحليل',
          ),
          BottomNavigationBarItem(
            icon: _buildAnimatedIcon(Icons.add_circle_outline, Icons.add_circle, 2),
            label: 'إضافة',
          ),
          BottomNavigationBarItem(
            icon: _buildAnimatedIcon(Icons.import_export_outlined, Icons.import_export, 3),
            label: 'البيانات',
          ),
          BottomNavigationBarItem(
            icon: _buildAnimatedIcon(Icons.settings_outlined, Icons.settings, 4),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    return AnimatedSwitcher(
      duration: AppTheme.animationFast,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        key: ValueKey(isSelected),
      ),
    )
        .animate(target: isSelected ? 1.0 : 0.0)
        .scaleXY(begin: 0.8, end: 1.0, duration: 200.ms)
        .fadeIn(duration: 150.ms);
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _onTabSelected(2); // Navigate to Add Transaction
        },
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      )
          .animate()
          .shimmer(
            delay: 2000.ms,
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    // Create screens list
    final screens = [
      widget.homeScreen,
      const AnalysisScreen(),
      const EnhancedAddTransactionScreen(),
      _buildDataManagementScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for wide screens
          if (isWideScreen)
            _buildNavigationRail(colorScheme)
                .animate()
                .slideX(begin: -1.0, duration: 300.ms)
                .fadeIn(duration: 300.ms),
          
          // Main content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: screens.length,
              itemBuilder: (context, index) {
                return screens[index]
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideX(
                      begin: 0.1,
                      end: 0.0,
                      duration: 300.ms,
                      curve: AppTheme.animationCurve,
                    );
              },
            ),
          ),
        ],
      ),
      
      // Bottom Navigation for mobile screens
      bottomNavigationBar: !isWideScreen 
          ? _buildBottomNavigation(colorScheme)
              .animate()
              .slideY(begin: 1.0, duration: 300.ms)
              .fadeIn(duration: 300.ms)
          : null,
      
      // Floating Action Button (only on mobile for Add Transaction)
      floatingActionButton: !isWideScreen && _currentIndex != 2
          ? _buildFloatingActionButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDataManagementScreen() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة البيانات'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.file_upload),
                text: 'استيراد',
              ),
              Tab(
                icon: Icon(Icons.file_download),
                text: 'تصدير',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ImportScreen(),
            ExportScreen(),
          ],
        ),
      ),
    );
  }
}