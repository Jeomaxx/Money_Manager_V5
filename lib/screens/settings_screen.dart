import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  User? _currentUser;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      final biometricAvailable = await _authService.isBiometricAvailable();
      final biometricEnabled = await _authService.isBiometricEnabled();
      
      setState(() {
        _currentUser = user;
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (value) {
        success = await _authService.enableBiometric();
      } else {
        success = await _authService.disableBiometric();
      }

      if (success) {
        setState(() {
          _biometricEnabled = value;
        });
        _showSuccessSnackBar(value ? 'تم تفعيل المصادقة البيومترية' : 'تم إلغاء المصادقة البيومترية');
      } else {
        _showErrorSnackBar('فشل في تغيير إعدادات المصادقة البيومترية');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء تغيير الإعدادات');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await _showLogoutConfirmDialog();
    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Management Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          'إدارة الحساب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_currentUser != null) ...[
                      _buildInfoItem('الاسم', _currentUser!.name),
                      _buildInfoItem('البريد الإلكتروني', _currentUser!.email),
                      _buildInfoItem('تاريخ الانضمام', 
                        '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}'),
                      const SizedBox(height: 16),
                      
                      // Biometric Toggle
                      if (_biometricAvailable)
                        ListTile(
                          leading: const Icon(Icons.fingerprint, color: Colors.indigo),
                          title: const Text('المصادقة البيومترية'),
                          subtitle: Text(_biometricEnabled ? 'مفعلة' : 'غير مفعلة'),
                          trailing: Switch(
                            value: _biometricEnabled,
                            onChanged: _isLoading ? null : _toggleBiometric,
                            activeColor: Colors.teal,
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('تسجيل الخروج'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'معلومات التطبيق',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem('اسم التطبيق', 'مدير المصروفات الشخصية'),
                    _buildInfoItem('الإصدار', '1.0.0'),
                    _buildInfoItem('المطور', 'Flutter App'),
                    _buildInfoItem('اللغة', 'العربية (Arabic)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data Management Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'إدارة البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Sample Data
                    ListTile(
                      leading: const Icon(Icons.data_usage, color: Colors.green),
                      title: const Text('إضافة بيانات تجريبية'),
                      subtitle: const Text('إضافة معاملات تجريبية لاختبار التطبيق'),
                      trailing: ElevatedButton(
                        onPressed: _isLoading ? null : _addSampleData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة'),
                      ),
                    ),
                    const Divider(),
                    
                    // Clear All Data
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('مسح جميع البيانات'),
                      subtitle: const Text('حذف جميع المعاملات (لا يمكن التراجع)'),
                      trailing: ElevatedButton(
                        onPressed: _isLoading ? null : _clearAllData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('مسح'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Features Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.featured_play_list, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          'مميزات التطبيق',
                          style: TextStyle(
                            fontSize: 18,
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
                      'الإدخال الصوتي',
                      'إضافة المعاملات باستخدام الصوت باللغة العربية',
                      Icons.mic,
                      Colors.blue,
                    ),
                    _buildFeatureItem(
                      'التحليل الشهري',
                      'عرض إحصائيات مفصلة ورسوم بيانية',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help, color: Colors.indigo),
                        const SizedBox(width: 8),
                        const Text(
                          'المساعدة والدعم',
                          style: TextStyle(
                            fontSize: 18,
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
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.bug_report, color: Colors.red),
                      title: const Text('الإبلاغ عن مشكلة'),
                      subtitle: const Text('إرسال تقرير عن مشكلة في التطبيق'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _reportIssue,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تطبيق مجاني لإدارة المالية الشخصية',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 - جميع الحقوق محفوظة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
        await _transactionService.addSampleData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة البيانات التجريبية بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في إضافة البيانات: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
        await _transactionService.clearAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم مسح جميع البيانات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في مسح البيانات: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
                backgroundColor: isDestructive ? Colors.red : Colors.blue,
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
          applicationIcon: const Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Colors.teal,
          ),
          children: [
            const Text(
              'تطبيق مجاني لإدارة المالية الشخصية باللغة العربية مع دعم كامل للتخطيط من اليمين إلى اليسار.',
            ),
            const SizedBox(height: 16),
            const Text('المميزات:'),
            const Text('• إضافة وتتبع المعاملات المالية'),
            const Text('• الإدخال الصوتي باللغة العربية'),
            const Text('• تحليل مفصل مع رسوم بيانية'),
            const Text('• تصدير واستيراد البيانات'),
            const Text('• واجهة عربية بالكامل'),
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
                SizedBox(height: 16),
                Text('1. إضافة معاملة جديدة:'),
                Text('   • اضغط على الزر الأزرق (+) في الشاشة الرئيسية'),
                Text('   • أو استخدم الزر الأحمر للإدخال الصوتي'),
                SizedBox(height: 12),
                Text('2. عرض التحليل الشهري:'),
                Text('   • اضغط على الزر البنفسجي (📊) في الشاشة الرئيسية'),
                SizedBox(height: 12),
                Text('3. تصدير البيانات:'),
                Text('   • اضغط على الزر الأخضر (📄) في الشاشة الرئيسية'),
                Text('   • اختر صيغة CSV أو Excel'),
                SizedBox(height: 12),
                Text('4. استيراد البيانات:'),
                Text('   • من القائمة الجانبية، اختر "استيراد البيانات"'),
                Text('   • اتبع التعليمات لرفع ملف CSV'),
                SizedBox(height: 12),
                Text('5. الإدخال الصوتي:'),
                Text('   • قل "أنفقت 100 جنيه على الطعام"'),
                Text('   • أو "كسبت 5000 جنيه من الراتب"'),
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

  void _reportIssue() {
    // Copy app info to clipboard
    final appInfo = '''
مدير المصروفات الشخصية
الإصدار: 1.0.0
المنصة: ${Theme.of(context).platform.name}
''';
    
    Clipboard.setData(ClipboardData(text: appInfo));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ معلومات التطبيق. يمكنك إرسالها مع تقرير المشكلة.'),
        backgroundColor: Colors.blue,
      ),
    );
    
    // In a real app, you would open email client or contact form
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الإبلاغ عن مشكلة'),
          content: const Text(
            'تم نسخ معلومات التطبيق إلى الحافظة. '
            'يرجى إرسال تقرير المشكلة مع هذه المعلومات إلى فريق التطوير.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }
}