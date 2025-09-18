import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../providers/theme_provider.dart';
import 'voice_recording_overlay.dart';

/// Professional floating action button for voice input
class VoiceInputFAB extends StatefulWidget {
  final Function(VoiceCommandResult)? onVoiceCommand;
  final bool enabled;

  const VoiceInputFAB({
    Key? key,
    this.onVoiceCommand,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<VoiceInputFAB> createState() => _VoiceInputFABState();
}

class _VoiceInputFABState extends State<VoiceInputFAB>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeechService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeSpeechService() async {
    _isInitialized = await _speechService.initialize();
    if (mounted) setState(() {});
    
    // Listen to voice command results
    _speechService.commandResults.listen((result) {
      if (mounted) {
        widget.onVoiceCommand?.call(result);
        _stopListening();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!_isInitialized || _isListening) return;

    final started = await _speechService.startListening();
    if (started && mounted) {
      setState(() {
        _isListening = true;
      });
      
      _pulseController.repeat(reverse: true);
      HapticFeedback.mediumImpact();
      
      // Show recording overlay
      _showRecordingOverlay();
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    await _speechService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      
      _pulseController.stop();
      _pulseController.reset();
      HapticFeedback.lightImpact();
    }
  }

  void _cancelListening() async {
    if (!_isListening) return;

    await _speechService.cancelListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      
      _pulseController.stop();
      _pulseController.reset();
      HapticFeedback.selectionClick();
    }
  }

  void _showRecordingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceRecordingOverlay(
        speechService: _speechService,
        onStop: _stopListening,
        onCancel: _cancelListening,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.enabled && _isInitialized ? _startListening : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isListening
                    ? LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Theme.of(context).primaryColor)
                        .withOpacity(0.3),
                    blurRadius: _isListening ? _pulseAnimation.value * 20 : 8,
                    spreadRadius: _isListening ? _pulseAnimation.value * 4 : 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: widget.enabled && _isInitialized ? _startListening : null,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        key: ValueKey(_isListening),
                        color: Colors.white,
                        size: _isListening ? 32 : 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Voice input status indicator
class VoiceInputStatus extends StatelessWidget {
  final bool isListening;
  final bool isInitialized;
  final String? error;

  const VoiceInputStatus({
    Key? key,
    required this.isListening,
    required this.isInitialized,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!isInitialized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'تحضير الميكروفون...',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (isListening) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'أستمع...',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_none,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'اضغط للتحدث',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}