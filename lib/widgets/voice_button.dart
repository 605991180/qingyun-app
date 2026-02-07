import 'package:flutter/material.dart';

class VoiceButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const VoiceButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 10.0, end: 25.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isListening ? _scaleAnimation.value : 1.0;
        final glowRadius = widget.isListening ? _glowAnimation.value : 12.0;
        
        return Semantics(
          button: true,
          label: widget.isListening ? '正在录音，点击停止' : '添加互动记录，长按开始语音输入',
          child: GestureDetector(
            onLongPressStart: (_) => widget.onLongPressStart?.call(),
            onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
            child: Container(
            width: 72 * scale,
            height: 72 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: widget.isListening
                    ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                    : [const Color(0xFFFF9800), const Color(0xFFF57C00)],
                center: Alignment.center,
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isListening 
                      ? const Color(0xFFFF5252) 
                      : const Color(0xFFFF9800))
                      .withAlpha(180),
                  blurRadius: glowRadius,
                  spreadRadius: glowRadius / 4,
                ),
                BoxShadow(
                  color: (widget.isListening 
                      ? const Color(0xFFFF5252) 
                      : const Color(0xFFFF9800))
                      .withAlpha(100),
                  blurRadius: glowRadius * 2,
                  spreadRadius: glowRadius / 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: widget.isListening ? '停止录音' : '添加互动',
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
