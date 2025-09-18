import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final bool enabled;

  const AnimatedFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  State<AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<AnimatedFormField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _shakeController;
  late Animation<double> _labelAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;
  String? _errorText;
  
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeAnimations() {
    _focusController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AppTheme.animationCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _setupListeners() {
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused) {
        HapticFeedback.lightImpact();
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });

    widget.controller.addListener(() {
      final hasText = widget.controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_focusController, _shakeController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * ((_shakeController.value * 4).round() % 2 == 0 ? 1 : -1),
            0,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [
                  if (_isFocused)
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Floating Label
                  AnimatedContainer(
                    duration: AppTheme.animationMedium,
                    curve: AppTheme.animationCurve,
                    margin: EdgeInsets.only(
                      left: AppTheme.spacingM,
                      bottom: _isFocused || _hasText ? AppTheme.spacingXs : 0,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: AppTheme.animationMedium,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: _isFocused
                            ? colorScheme.primary
                            : _errorText != null
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                        fontWeight: _isFocused || _hasText 
                            ? FontWeight.w600 
                            : FontWeight.w500,
                        fontSize: _isFocused || _hasText ? 14 : 16,
                      ),
                      child: Text(widget.label),
                    )
                        .animate(target: _isFocused || _hasText ? 1.0 : 0.0)
                        .scaleXY(begin: 1.1, end: 1.0, duration: 200.ms)
                        .fadeIn(duration: 200.ms),
                  ),
                  
                  // Text Field
                  TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    obscureText: widget.obscureText,
                    maxLines: widget.maxLines,
                    onTap: widget.onTap,
                    readOnly: widget.readOnly,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: widget.prefixIcon != null
                          ? Icon(
                              widget.prefixIcon,
                              color: _isFocused
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            )
                              .animate(target: _isFocused ? 1.0 : 0.0)
                              .scaleXY(begin: 1.0, end: 1.1, duration: 200.ms)
                          : null,
                      suffixIcon: widget.suffixIcon,
                      filled: true,
                      fillColor: _isFocused
                          ? colorScheme.primaryContainer.withOpacity(0.1)
                          : colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                    validator: (value) {
                      final error = widget.validator?.call(value);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (error != _errorText) {
                          setState(() {
                            _errorText = error;
                          });
                          if (error != null) {
                            _triggerShakeAnimation();
                          }
                        }
                      });
                      return error;
                    },
                  ),
                  
                  // Error Text Animation
                  AnimatedContainer(
                    duration: AppTheme.animationMedium,
                    height: _errorText != null ? 24 : 0,
                    child: AnimatedOpacity(
                      duration: AppTheme.animationMedium,
                      opacity: _errorText != null ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppTheme.spacingM,
                          top: AppTheme.spacingXs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Expanded(
                              child: Text(
                                _errorText ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}