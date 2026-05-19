import 'package:flutter/material.dart';

class FloatingDamageNumber extends StatefulWidget {
  final int damage;
  final Color color;
  final bool isPlayerDamage;
  final VoidCallback onComplete;

  const FloatingDamageNumber({
    super.key,
    required this.damage,
    required this.color,
    required this.isPlayerDamage,
    required this.onComplete,
  });

  @override
  State<FloatingDamageNumber> createState() => _FloatingDamageNumberState();
}

class _FloatingDamageNumberState extends State<FloatingDamageNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _yOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _yOffset = Tween(
      begin: 0.0,
      end: -60.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Positioned(
        left: widget.isPlayerDamage ? screenW * 0.3 : screenW * 0.55,
        top: screenH * 0.35 + _yOffset.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Text(
            widget.isPlayerDamage ? '-${widget.damage}' : '+${widget.damage}',
            style: TextStyle(
              color: widget.color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
