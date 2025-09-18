import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _speechEnabled = true;
  bool _notificationsEnabled = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load user preferences from SharedPreferences if needed
    setState(() {
      _speechEnabled = true;
      _notificationsEnabled = true;
      _hapticFeedback = true;
    });
  }

  Future<void> _toggleSetting(String setting, bool value) async {
    setState(() {
      switch (setting) {
        case 'speech':
          _speechEnabled = value;
          break;
        case 'notifications':
          _notificationsEnabled = value;
          break;
        case 'haptic':
          _hapticFeedback = value;
          break;
      }
    });
    
    HapticFeedback.lightImpact();
    _showSuccessSnackBar('تم تحديث الإعدادات بنجاح');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Settings Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المظهر والألوان',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          children: [
                            _buildThemeOption(
                              'النظام',
                              'يتبع إعدادات النظام',
                              Icons.settings_system_daydream,
                              ThemeMode.system,
                              themeProvider.themeMode,
                              themeProvider.setThemeMode,
                            ),
                            _buildThemeOption(
                              'المظهر الفاتح',
                              'استخدام الألوان الفاتحة',
                              Icons.light_mode,
                              ThemeMode.light,
                              themeProvider.themeMode,
                              themeProvider.setThemeMode,
                            ),
                            _buildThemeOption(
                              'المظهر الداكن',
                              'استخدام الألوان الداكنة',
                              Icons.dark_mode,
                              ThemeMode.dark,
                              themeProvider.themeMode,
                              themeProvider.setThemeMode,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Settings Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إعدادات التطبيق',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Speech Recognition Toggle
                    _buildSwitchTile(
                      'الإدخال الصوتي',
                      'تفعيل إضافة المصروفات بالصوت',
                      Icons.mic,
                      Colors.blue,
                      _speechEnabled,
                      (value) => _toggleSetting('speech', value),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Notifications Toggle
                    _buildSwitchTile(
                      'الإشعارات',
                      'تفعيل تذكيرات المصروفات',
                      Icons.notifications,
                      Colors.orange,
                      _notificationsEnabled,
                      (value) => _toggleSetting('notifications', value),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Haptic Feedback Toggle
                    _buildSwitchTile(
                      'الاهتزاز التفاعلي',
                      'اهتزاز عند اللمس والتنبيهات',
                      Icons.vibration,
                      Colors.purple,
                      _hapticFeedback,
                      (value) => _toggleSetting('haptic', value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Management Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إدارة الحساب',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoItem('نوع المستخدم', 'مستخدم محلي'),
                    _buildInfoItem('تاريخ الإنشاء', 'اليوم'),
                    _buildInfoItem('عدد المعاملات', '3'),
                    
                    const SizedBox(height: 16),
                    
                    // Data Management Options
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addSampleData,
                            icon: const Icon(Icons.data_usage),
                            label: const Text('بيانات تجريبية'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _clearAllData,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('مسح البيانات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Features Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.featured_play_list,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'مميزات التطبيق',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFeatureItem(
                      'إدارة المعاملات المالية',
                      'إضافة وتتبع الدخل والمصروفات',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                    _buildFeatureItem(
                      'الإدخال الصوتي الذكي',
                      'إضافة المعاملات باستخدام الصوت مع الذكاء الاصطناعي',
                      Icons.mic,
                      Colors.blue,
                    ),
                    _buildFeatureItem(
                      'التحليل المالي',
                      'تحليل ذكي للمصروفات باستخدام الذكاء الاصطناعي',
                      Icons.analytics,
                      Colors.purple,
                    ),
                    _buildFeatureItem(
                      'التصدير والاستيراد',
                      'تصدير واستيراد البيانات بصيغ CSV و Excel',
                      Icons.import_export,
                      Colors.orange,
                    ),
                    _buildFeatureItem(
                      'الواجهة العربية',
                      'دعم كامل للغة العربية والتخطيط من اليمين إلى اليسار',
                      Icons.language,
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Support Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المساعدة والدعم',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.blue),
                      title: const Text('حول التطبيق'),
                      subtitle: const Text('معلومات التطبيق والشروط'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showAboutDialog,
                    ),
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Colors.green),
                      title: const Text('كيفية الاستخدام'),
                      subtitle: const Text('دليل سريع لاستخدام التطبيق'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showHelpDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'مدير المصروفات الشخصية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تطبيق مجاني لإدارة المالية الشخصية بالذكاء الاصطناعي',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2025 - جميع الحقوق محفوظة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    IconData icon,
    ThemeMode themeMode,
    ThemeMode currentMode,
    Function(ThemeMode) onChanged,
  ) {
    final isSelected = currentMode == themeMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Radio<ThemeMode>(
          value: themeMode,
          groupValue: currentMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              onChanged(value);
              _showSuccessSnackBar('تم تغيير المظهر بنجاح');
            }
          },
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(themeMode);
          _showSuccessSnackBar('تم تغيير المظهر بنجاح');
        },
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSampleData() async {
    final confirmed = await _showConfirmationDialog(
      'إضافة بيانات تجريبية',
      'هل أنت متأكد من رغبتك في إضافة بيانات تجريبية؟ سيتم إضافة عدة معاملات للاختبار.',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate adding sample data
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          _showSuccessSnackBar('تم إضافة البيانات التجريبية بنجاح');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('فشل في إضافة البيانات');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      'مسح جميع البيانات',
      'تحذير: سيتم حذف جميع المعاملات نهائياً ولا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟',
      isDestructive: true,
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate clearing data
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          _showSuccessSnackBar('تم مسح جميع البيانات بنجاح');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('فشل في مسح البيانات');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content, {bool isDestructive = false}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isDestructive ? 'حذف' : 'تأكيد'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AboutDialog(
          applicationName: 'مدير المصروفات الشخصية',
          applicationVersion: '1.0.0',
          applicationIcon: Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          children: [
            const Text(
              'تطبيق مجاني لإدارة المالية الشخصية باللغة العربية مع الذكاء الاصطناعي ودعم كامل للتخطيط من اليمين إلى اليسار.',
            ),
            const SizedBox(height: 16),
            const Text(
              'المميزات:\n'
              '• إدخال صوتي ذكي باللغة العربية\n'
              '• تحليل مالي بالذكاء الاصطناعي\n'
              '• واجهة عربية كاملة\n'
              '• مظهر فاتح وداكن\n'
              '• تصدير واستيراد البيانات',
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
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('كيفية الاستخدام'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'دليل سريع لاستخدام التطبيق:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '١. إضافة المعاملات:\n'
                  '   • اضغط على زر الميكروفون\n'
                  '   • قل "دفعت 50 جنيه قهوة"\n'
                  '   • سيتم إضافة المعاملة تلقائياً\n\n'
                  '٢. عرض التحليل:\n'
                  '   • اذهب إلى تبويب "التحليل"\n'
                  '   • شاهد الرسوم البيانية والإحصائيات\n\n'
                  '٣. تغيير المظهر:\n'
                  '   • اذهب إلى "الإعدادات"\n'
                  '   • اختر المظهر المفضل\n\n'
                  '٤. تصدير البيانات:\n'
                  '   • اذهب إلى تبويب "البيانات"\n'
                  '   • اختر "تصدير" لحفظ البيانات',
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