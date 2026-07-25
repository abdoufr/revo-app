import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

class BouncingCartIcon extends ConsumerStatefulWidget {
  final Widget child;
  const BouncingCartIcon({super.key, required this.child});

  @override
  ConsumerState<BouncingCartIcon> createState() => _BouncingCartIconState();
}

class _BouncingCartIconState extends ConsumerState<BouncingCartIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        final currentCount = ref.read(cartProvider).fold(0, (sum, item) => sum + item.quantity);
        if (currentCount > 0) {
          _controller.forward(from: 0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
