import 'dart:async';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'voice_transaction_parser.dart';
import 'ai_client_service.dart';
import '../models/transaction.dart';

/// Comprehensive speech service for voice-to-transaction conversion
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  final AIClientService _aiClient = AIClientService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastTranscript = '';
  
  // Speech recognition results stream
  final StreamController<SpeechRecognitionResult> _speechResultController = 
      StreamController<SpeechRecognitionResult>.broadcast();
  
  // Voice command results stream
  final StreamController<VoiceCommandResult> _commandResultController = 
      StreamController<VoiceCommandResult>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastTranscript => _lastTranscript;
  Stream<SpeechRecognitionResult> get speechResults => _speechResultController.stream;
  Stream<VoiceCommandResult> get commandResults => _commandResultController.stream;

  /// Initialize speech service and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: true,
      );

      if (_isInitialized) {
        print('✅ Speech service initialized successfully');
        
        // Test AI client connection
        final aiAvailable = await _aiClient.testConnection();
        print('AI client available: $aiAvailable');
      } else {
        print('❌ Failed to initialize speech recognition');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Speech service initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start listening for voice commands
  Future<bool> startListening({
    Duration timeout = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      print('⚠️ Already listening');
      return true;
    }

    try {
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      final success = await _speech.listen(
        onResult: (result) => _onSpeechResult(result),
        listenFor: timeout,
        pauseFor: pauseFor,
        partialResults: true,
        localeId: 'ar-EG', // Arabic (Egypt) as primary, will fallback to en-US if needed
        cancelOnError: false,
      );

      if (success) {
        _isListening = true;
        print('🎤 Started listening for voice commands');
      } else {
        print('❌ Failed to start listening');
      }

      return success;
    } catch (e) {
      print('❌ Start listening error: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      HapticFeedback.lightImpact();
      print('🔇 Stopped listening');
    } catch (e) {
      print('❌ Stop listening error: $e');
    }
  }

  /// Cancel current listening session
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      HapticFeedback.selectionClick();
      print('❌ Cancelled listening');
    } catch (e) {
      print('❌ Cancel listening error: $e');
    }
  }

  /// Process voice command to extract transaction
  Future<VoiceCommandResult> processVoiceCommand(String transcript) async {
    if (transcript.trim().isEmpty) {
      return VoiceCommandResult(
        success: false,
        error: 'النص فارغ',
        transcript: transcript,
      );
    }

    try {
      // First, try local parsing for speed
      final localResult = VoiceTransactionParser.parseVoiceInput(transcript);
      
      VoiceCommandResult result;
      
      // If local parsing has good confidence, use it
      if (localResult.isValid && localResult.amount != null && localResult.amount! > 0) {
        result = VoiceCommandResult(
          success: true,
          transcript: transcript,
          parsedTransaction: localResult,
          confidence: 0.8, // Local parsing confidence
          source: 'local',
        );
      } else {
        // Use AI parsing for better accuracy
        try {
          final aiResult = await _aiClient.parseTransaction(transcript);
          
          if (aiResult != null && aiResult.confidence > 0.5) {
            // Convert AI result to ParsedTransaction
            final parsedTransaction = ParsedTransaction()
              ..type = aiResult.type
              ..amount = aiResult.amount
              ..category = aiResult.category
              ..note = aiResult.note;
            
            result = VoiceCommandResult(
              success: true,
              transcript: transcript,
              parsedTransaction: parsedTransaction,
              confidence: aiResult.confidence,
              source: 'ai',
            );
          } else {
            // Fallback to local result even if not perfect
            result = VoiceCommandResult(
              success: localResult.amount != null && localResult.amount! > 0,
              transcript: transcript,
              parsedTransaction: localResult,
              confidence: 0.3,
              source: 'local_fallback',
              error: 'لم أتمكن من فهم الأمر بوضوح',
            );
          }
        } catch (aiError) {
          print('AI parsing failed: $aiError');
          // Fallback to local result
          result = VoiceCommandResult(
            success: localResult.amount != null && localResult.amount! > 0,
            transcript: transcript,
            parsedTransaction: localResult,
            confidence: 0.3,
            source: 'local_fallback',
            error: 'خدمة الذكاء الاصطناعي غير متاحة حالياً',
          );
        }
      }

      // Emit result
      _commandResultController.add(result);
      return result;
      
    } catch (e) {
      print('❌ Voice command processing error: $e');
      final errorResult = VoiceCommandResult(
        success: false,
        transcript: transcript,
        error: 'حدث خطأ في معالجة الأمر الصوتي',
      );
      _commandResultController.add(errorResult);
      return errorResult;
    }
  }

  /// Get available languages for speech recognition
  Future<List<LocaleName>> getAvailableLanguages() async {
    if (!_isInitialized) return [];
    final locales = await _speech.locales();
    return locales.map((l) => LocaleName(l.localeId, l.name)).toList();
  }

  /// Check if device supports speech recognition
  Future<bool> isSpeechAvailable() async {
    return await _speech.initialize();
  }

  // Private methods
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastTranscript = result.recognizedWords;
    _speechResultController.add(result);
    
    print('🎤 Speech result: ${result.recognizedWords} (confidence: ${result.confidence})');
    
    // If speech recognition is final, process the command
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _processCommandAsync(result.recognizedWords);
    }
  }

  void _onSpeechError(dynamic error) {
    print('❌ Speech error: $error');
    _commandResultController.add(VoiceCommandResult(
      success: false,
      transcript: _lastTranscript,
      error: 'خطأ في التعرف على الصوت: $error',
    ));
  }

  void _onSpeechStatus(String status) {
    print('🎤 Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  void _processCommandAsync(String transcript) {
    // Process command in background
    processVoiceCommand(transcript).catchError((error) {
      print('❌ Async command processing error: $error');
    });
  }

  /// Dispose resources
  void dispose() {
    _speechResultController.close();
    _commandResultController.close();
    _speech.cancel();
  }
}

/// Result of speech recognition
class SpeechRecognitionResult {
  final String recognizedWords;
  final bool finalResult;
  final double confidence;

  SpeechRecognitionResult({
    required this.recognizedWords,
    required this.finalResult,
    required this.confidence,
  });
}

/// Result of voice command processing
class VoiceCommandResult {
  final bool success;
  final String transcript;
  final ParsedTransaction? parsedTransaction;
  final double confidence;
  final String source;
  final String? error;

  VoiceCommandResult({
    required this.success,
    required this.transcript,
    this.parsedTransaction,
    this.confidence = 0.0,
    this.source = 'unknown',
    this.error,
  });

  bool get hasValidTransaction => 
      success && 
      parsedTransaction != null && 
      parsedTransaction!.isValid;

  @override
  String toString() {
    return 'VoiceCommandResult(success: $success, confidence: $confidence, source: $source, error: $error)';
  }
}

/// Localization names for speech recognition
class LocaleName {
  final String localeId;
  final String name;

  LocaleName(this.localeId, this.name);
}