import 'package:flutter/material.dart';

/// A high-performance, 60/120 FPS butter-smooth tab transition stack.
///
/// Uses [SlideTransition], [FadeTransition], and [RepaintBoundary] so that
/// the GPU composites existing layers directly without rebuilding or repainting
/// pages on each animation frame (zero `saveLayer` jank).
///
/// Preserves the state of all pages (scroll positions, inputs, etc.) like [IndexedStack].
class NavTabTransitionStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final double slideOffset;

  const NavTabTransitionStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
    this.slideOffset = 0.06,
  });

  @override
  State<NavTabTransitionStack> createState() => _NavTabTransitionStackState();
}

class _NavTabTransitionStackState extends State<NavTabTransitionStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;

  late Animation<Offset> _inSlide;
  late Animation<Offset> _outSlide;
  late Animation<double> _inFade;
  late Animation<double> _outFade;

  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _initAnimations(forward: true);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousIndex = _currentIndex;
          });
        }
      }
    });
  }

  void _initAnimations({required bool forward}) {
    final dx = forward ? widget.slideOffset : -widget.slideOffset;

    _inSlide = Tween<Offset>(
      begin: Offset(dx, 0),
      end: Offset.zero,
    ).animate(_curved);

    _outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dx, 0),
    ).animate(_curved);

    _inFade = Tween<double>(begin: 0.0, end: 1.0).animate(_curved);
    _outFade = Tween<double>(begin: 1.0, end: 0.0).animate(_curved);
  }

  @override
  void didUpdateWidget(NavTabTransitionStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final forward = widget.index >= _currentIndex;
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _isAnimating = true;

      _initAnimations(forward: forward);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == _currentIndex;
        final isPrevious = i == _previousIndex && _isAnimating;

        // If neither current nor transitioning outgoing page, hide and pause tickers
        if (!isCurrent && !isPrevious) {
          return Offstage(
            offstage: true,
            child: TickerMode(
              enabled: false,
              child: widget.children[i],
            ),
          );
        }

        Widget child = RepaintBoundary(
          child: widget.children[i],
        );

        if (_isAnimating) {
          if (isPrevious) {
            child = IgnorePointer(
              child: SlideTransition(
                position: _outSlide,
                child: FadeTransition(
                  opacity: _outFade,
                  child: child,
                ),
              ),
            );
          } else if (isCurrent) {
            child = SlideTransition(
              position: _inSlide,
              child: FadeTransition(
                opacity: _inFade,
                child: child,
              ),
            );
          }
        }

        return Offstage(
          offstage: false,
          child: TickerMode(
            enabled: isCurrent,
            child: child,
          ),
        );
      }),
    );
  }
}
