import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final bool isSuccess;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.isSuccess = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.padding,
    this.borderRadius,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _successController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successRotationAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _successScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _successRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _triggerSuccessAnimation();
    }
    
    if (widget.isLoading && !oldWidget.isLoading) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSuccessAnimation() {
    HapticFeedback.mediumImpact();
    _successController.forward().then((_) {
      _successController.reverse();
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final backgroundColor = widget.backgroundColor ?? colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? colorScheme.onPrimary;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressController,
        _successController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * 
                _successScaleAnimation.value * 
                _pulseAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: AppTheme.animationMedium,
              width: widget.width,
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXl,
                vertical: AppTheme.spacingM,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isSuccess
                      ? [Colors.green, Colors.green.shade600]
                      : [backgroundColor, backgroundColor.withOpacity(0.8)],
                ),
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess ? Colors.green : backgroundColor)
                        .withOpacity(_isPressed ? 0.4 : 0.2),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                    spreadRadius: _isPressed ? 0 : 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(duration: 1000.ms)
                  else if (widget.isSuccess)
                    Transform.rotate(
                      angle: _successRotationAnimation.value * 3.14159,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                        .animate()
                        .scaleXY(begin: 0.5, duration: 300.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms)
                  else if (widget.icon != null)
                    Icon(
                      widget.icon,
                      color: foregroundColor,
                      size: 20,
                    )
                        .animate(target: _isPressed ? 1.0 : 0.0)
                        .scaleXY(begin: 1.0, end: 0.9, duration: 100.ms),
                  
                  if ((widget.isLoading || widget.isSuccess || widget.icon != null) && 
                      widget.text.isNotEmpty)
                    const SizedBox(width: AppTheme.spacingS),
                  
                  if (widget.text.isNotEmpty)
                    AnimatedDefaultTextStyle(
                      duration: AppTheme.animationMedium,
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: widget.isSuccess ? Colors.white : foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(
                        widget.isSuccess ? 'تم الحفظ!' : widget.text,
                      ),
                    )
                        .animate(target: widget.isSuccess ? 1.0 : 0.0)
                        .fadeOut(duration: 200.ms)
                        .then()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.2, duration: 300.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}