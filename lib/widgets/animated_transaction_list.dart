import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list_item.dart';
import '../theme/app_theme.dart';

class AnimatedTransactionList extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(Transaction)? onTransactionTap;
  final Function(Transaction)? onTransactionDelete;
  final VoidCallback? onShowAll;

  const AnimatedTransactionList({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.onTransactionDelete,
    this.onShowAll,
  });

  @override
  State<AnimatedTransactionList> createState() => _AnimatedTransactionListState();
}

class _AnimatedTransactionListState extends State<AnimatedTransactionList>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Transaction> _displayedTransactions = [];
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTransactions();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: AppTheme.animationCurve,
    ));

    _headerController.forward();
  }

  void _initializeTransactions() {
    // Initialize with existing transactions
    _displayedTransactions = List.from(widget.transactions);
    
    // Animate initial load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listKey.currentState != null) {
        for (int i = 0; i < _displayedTransactions.length; i++) {
          Future.delayed(Duration(milliseconds: i * 100), () {
            if (_listKey.currentState != null) {
              _listKey.currentState!.insertItem(i, duration: AppTheme.animationMedium);
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedTransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle transaction list changes with animations
    _updateTransactionList(oldWidget.transactions, widget.transactions);
  }

  void _updateTransactionList(List<Transaction> oldList, List<Transaction> newList) {
    // Find added transactions
    final addedTransactions = newList
        .where((transaction) => !oldList.any((old) => old.id == transaction.id))
        .toList();

    // Find removed transactions
    final removedTransactions = oldList
        .where((transaction) => !newList.any((new_) => new_.id == transaction.id))
        .toList();

    // Animate additions
    for (final transaction in addedTransactions) {
      _addTransactionWithAnimation(transaction);
    }

    // Animate removals
    for (final transaction in removedTransactions) {
      _removeTransactionWithAnimation(transaction);
    }
  }

  void _addTransactionWithAnimation(Transaction transaction) {
    final insertIndex = 0; // Add new transactions at the top
    
    setState(() {
      _displayedTransactions.insert(insertIndex, transaction);
    });

    _listKey.currentState?.insertItem(
      insertIndex,
      duration: AppTheme.animationMedium,
    );

    // Add haptic feedback for successful addition
    HapticFeedback.mediumImpact();
  }

  void _removeTransactionWithAnimation(Transaction transaction) {
    final removeIndex = _displayedTransactions.indexWhere(
      (t) => t.id == transaction.id,
    );
    
    if (removeIndex == -1) return;

    final removedTransaction = _displayedTransactions[removeIndex];
    
    setState(() {
      _displayedTransactions.removeAt(removeIndex);
    });

    _listKey.currentState?.removeItem(
      removeIndex,
      (context, animation) => _buildRemovedItem(removedTransaction, animation),
      duration: AppTheme.animationMedium,
    );

    // Add haptic feedback for deletion
    HapticFeedback.lightImpact();
  }

  Widget _buildRemovedItem(Transaction transaction, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: TransactionListItem(
          transaction: transaction,
          onTap: null, // Disable interaction during removal
          onLongPress: null,
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index, Animation<double> animation) {
    if (index >= _displayedTransactions.length) return const SizedBox.shrink();
    
    final transaction = _displayedTransactions[index];
    
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: AppTheme.animationCurve)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.8, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
          ),
          child: TransactionListItem(
            transaction: transaction,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTransactionTap?.call(transaction);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showDeleteConfirmation(transaction);
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المعاملة'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onTransactionDelete?.call(transaction);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, -0.5),
              end: Offset.zero,
            ).animate(_headerAnimation),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  )
                      .animate()
                      .scale(delay: 200.ms, duration: 300.ms)
                      .fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'المعاملات الأخيرة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 300.ms)
                      .slideX(begin: 0.2, delay: 300.ms, duration: 300.ms),
                  const Spacer(),
                  if (widget.onShowAll != null)
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onShowAll!();
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      label: const Text('عرض الكل'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 300.ms)
                        .scaleXY(begin: 0.8, delay: 400.ms, duration: 300.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'لا توجد معاملات حتى الآن',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.3, delay: 400.ms, duration: 500.ms),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'ابدأ بإضافة معاملتك الأولى من خلال النقر على زر الإضافة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.3, delay: 600.ms, duration: 500.ms),
        ],
      ),
    )
        .animate()
        .scaleXY(begin: 0.9, delay: 800.ms, duration: 500.ms)
        .fadeIn(delay: 800.ms, duration: 500.ms);
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        
        // Transaction List or Empty State
        if (_displayedTransactions.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: 0, // Start with 0, items will be added via animation
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Parent handles scrolling
              itemBuilder: _buildListItem,
            ),
          ),
      ],
    );
  }
}