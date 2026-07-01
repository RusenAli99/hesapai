import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;

  const ChatInputField({
    super.key,
    required this.onSend,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  
  // Speech-to-text properties
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  // Animation controller for pulsing microphone effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Rotating placeholders for better onboarding/UX
  late Timer _placeholderTimer;
  int _placeholderIndex = 0;
  final List<String> _placeholders = [
    'Bugün markette 450 TL harcadım',
    'Maaşım yattı 35.000 TL',
    'Benzine 1200 TL verdim',
    'Freelance projeden 5000 TL kazandım',
    'Kiraya 8500 TL ödedim',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(_onTextChanged);
    
    // Rotating placeholders timer
    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isListening) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });

    // Pulse animation controller for mic button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('Speech Status: $status');
            if (status == 'done' || status == 'notListening') {
              if (mounted) {
                setState(() {
                  _isListening = false;
                  _pulseController.stop();
                });
              }
            }
          },
          onError: (val) {
            print('Speech Error: $val');
            if (mounted) {
              setState(() {
                _isListening = false;
                _pulseController.stop();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ses tanıma başlatılamadı. İzinlerinizi kontrol edin.'),
                  backgroundColor: AppColors.expense,
                ),
              );
            }
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
          });
          _pulseController.repeat(reverse: true);
          
          _speech.listen(
            localeId: 'tr_TR', // Turkish speech recognition
            listenFor: const Duration(seconds: 20),
            pauseFor: const Duration(seconds: 4),
            onResult: (val) {
              if (mounted) {
                setState(() {
                  _controller.text = val.recognizedWords;
                  _onTextChanged();
                });
              }
            },
          );
        }
      } catch (e) {
        print("Speech recognition error: $e");
        if (mounted) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _pulseController.stop();
        });
      }
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _placeholderTimer.cancel();
    _pulseController.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // TextField
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25),
                  border: _isListening
                      ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
                      : null,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontFamily: 'sans-serif',
                  ),
                  decoration: InputDecoration(
                    hintText: _isListening 
                        ? 'Dinleniyor... Konuşun' 
                        : _placeholders[_placeholderIndex],
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: _isListening 
                          ? Colors.red.withOpacity(0.6) 
                          : (isDark ? Colors.white30 : Colors.black38),
                      fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                      fontFamily: 'sans-serif',
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Action Button (Send or Mic)
            ScaleTransition(
              scale: _pulseAnimation,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: _isListening
                    ? Colors.red.withOpacity(0.2)
                    : (_hasText ? AppColors.primary : Colors.grey.withOpacity(0.12)),
                child: IconButton(
                  icon: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : (_isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
                    color: _isListening
                        ? Colors.red
                        : (_hasText
                            ? Colors.white
                            : (isDark ? Colors.white30 : Colors.black26)),
                    size: 20,
                  ),
                  onPressed: _hasText
                      ? _handleSubmit
                      : _listen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
