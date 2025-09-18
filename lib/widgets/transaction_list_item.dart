import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionListItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) {
      switch (category.toLowerCase()) {
        case 'راتب':
        case 'salary':
          return Icons.work_outline;
        case 'استثمار':
        case 'investment':
          return Icons.trending_up;
        case 'هدية':
        case 'gift':
          return Icons.card_giftcard;
        case 'بيع':
        case 'sale':
          return Icons.sell;
        default:
          return Icons.add_circle_outline;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'طعام':
        case 'food':
          return Icons.restaurant;
        case 'مواصلات':
        case 'transportation':
          return Icons.directions_car;
        case 'تسوق':
        case 'shopping':
          return Icons.shopping_bag;
        case 'فواتير':
        case 'bills':
          return Icons.receipt_long;
        case 'صحة':
        case 'health':
          return Icons.medical_services;
        case 'ترفيه':
        case 'entertainment':
          return Icons.movie;
        case 'تعليم':
        case 'education':
          return Icons.school;
        case 'منزل':
        case 'home':
          return Icons.home;
        default:
          return Icons.remove_circle_outline;
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == 'دخل';
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    (isIncome ? Colors.green : Colors.red).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed 
                        ? (isIncome ? Colors.green : Colors.red).withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: const Offset(0, 4),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
                border: Border.all(
                  color: _isPressed 
                      ? (isIncome ? Colors.green : Colors.red).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Animated Leading Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  (isIncome ? Colors.green : Colors.red).withOpacity(0.2),
                                  (isIncome ? Colors.green : Colors.red).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: (isIncome ? Colors.green : Colors.red).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(widget.transaction.category, isIncome),
                              color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category and Amount Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.transaction.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isIncome ? Colors.green : Colors.red)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${isIncome ? '+' : '-'}${widget.transaction.amount.toStringAsFixed(2)} ج.م',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome 
                                        ? Colors.green.shade700 
                                        : Colors.red.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Note if available
                          if (widget.transaction.note != null && 
                              widget.transaction.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                widget.transaction.note!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Date and Type Row
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFormat.format(widget.transaction.date),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green : Colors.red)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isIncome 
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 14,
                                      color: isIncome 
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.transaction.type,
                                      style: TextStyle(
                                        color: isIncome 
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}