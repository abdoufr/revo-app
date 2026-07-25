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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartProvider, (previous, next) {
      final prevCount = previous?.fold(0, (sum, item) => sum + item.quantity) ?? 0;
      final nextCount = next.fold(0, (sum, item) => sum + item.quantity);
      if (nextCount > prevCount) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _controller.forward(from: 0.0);
          }
        });
      }
    });

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
