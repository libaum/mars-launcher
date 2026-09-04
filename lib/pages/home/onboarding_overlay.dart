/// First-run coach marks. Sits on top of the real home screen, points at the
/// real elements and swallows every gesture, so no step can accidentally leave
/// the flow. Shown once — see [Keys.onboardingCompleted].

import 'package:flutter/material.dart';

enum _StepKind {
  /// Text only, dark overlay.
  plain,

  /// Frames the real shortcut slots, overlay stays light enough to see them.
  frame,

  /// Hints the swipe-up gesture with a chevron near the bottom.
  swipeUp,

  /// Hints the long press with a pulsing ring in the middle.
  hold,
}

class _Step {
  final String title;
  final String body;

  /// The one phrase inside [body] that carries the accent color. Mars keeps
  /// red meaningful — at most one red element per screen.
  final String? accent;
  final _StepKind kind;

  const _Step(this.title, this.body, this.kind, {this.accent});

  double get scrimOpacity => kind == _StepKind.plain ? 0.72 : 0.35;
}

const _steps = <_Step>[
  _Step(
    'Welcome to Mars',
    "Not much here. That's the point.",
    _StepKind.plain,
  ),
  _Step(
    'Your Shortcuts',
    'Hold a slot to set an app. Tap it to open.',
    _StepKind.frame,
    accent: 'Hold a slot',
  ),
  _Step(
    'Search',
    'Swipe up to find all your other apps super fast!',
    _StepKind.swipeUp,
    accent: 'Swipe up',
  ),
  _Step(
    'Settings',
    'Long tap on empty space to customize your experience.',
    _StepKind.hold,
    accent: 'Long tap on empty space',
  ),
  _Step(
    'The Rest Is Yours',
    'Widgets, themes, gestures. Discover them as you go. '
    'For reference look into settings → cheat sheet.',
    _StepKind.plain,
    accent: 'cheat sheet',
  ),
];

const _kAnimDuration = Duration(milliseconds: 450);
const _kSideMargin = 34.0;
const _kFrameMargin = 20.0;

/// Shared text height of the three pointing steps, as a fraction of the screen.
const _kTextTopFraction = 0.20;

class OnboardingOverlay extends StatefulWidget {
  /// Key on the shortcut fragment, used to frame the real slots in step 2.
  final GlobalKey shortcutsKey;
  final VoidCallback onFinished;

  const OnboardingOverlay({
    super.key,
    required this.shortcutsKey,
    required this.onFinished,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Rect? _targetRect;
  late final AnimationController _pulse;

  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Translates the shortcut fragment's box into this overlay's coordinates.
  void _measureTarget() {
    final targetContext = widget.shortcutsKey.currentContext;
    final self = context.findRenderObject();
    if (targetContext == null || self is! RenderBox) return;
    final target = targetContext.findRenderObject();
    if (target is! RenderBox || !target.hasSize) return;

    final topLeft = self.globalToLocal(target.localToGlobal(Offset.zero));
    /// Only the vertical extent comes from the slots — horizontally the frame
    /// keeps a fixed margin, so it reads as one block instead of hugging the
    /// longest app name.
    final rect = Rect.fromLTRB(
      _kFrameMargin,
      topLeft.dy - 14,
      self.size.width - _kFrameMargin,
      topLeft.dy + target.size.height + 14,
    );
    if (rect != _targetRect && mounted) {
      setState(() => _targetRect = rect);
    }
  }

  void _next() {
    if (_index == _steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _index++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final size = MediaQuery.of(context).size;
    final isLast = _index == _steps.length - 1;

    return GestureDetector(
      /// Swallow every gesture so no step opens a real function.
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onDoubleTap: () {},
      onLongPress: () {},
      onVerticalDragUpdate: (_) {},
      onHorizontalDragUpdate: (_) {},
      child: Stack(
        children: [
          AnimatedContainer(
            duration: _kAnimDuration,
            curve: Curves.easeInOut,
            color: Colors.black.withValues(alpha: _step.scrimOpacity),
          ),
          if (_step.kind == _StepKind.frame && _targetRect != null)
            AnimatedPositioned(
              duration: _kAnimDuration,
              curve: Curves.easeInOut,
              left: _targetRect!.left,
              top: _targetRect!.top,
              width: _targetRect!.width,
              height: _targetRect!.height,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Opacity(
                    opacity: 0.45 + 0.55 * _pulse.value,
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          if (_step.kind == _StepKind.swipeUp)
            _buildSwipeUpHint(size, accentColor),
          if (_step.kind == _StepKind.hold) _buildHoldHint(accentColor),
          _buildText(size, accentColor),
          if (!isLast) _buildSkip(),
          _buildNav(isLast, accentColor),
        ],
      ),
    );
  }

  Widget _buildSwipeUpHint(Size size, Color accentColor) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: size.height * 0.22,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 14 * (1 - _pulse.value) - 7),
              child: Opacity(
                opacity: 0.4 + 0.6 * _pulse.value,
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.keyboard_arrow_up,
            size: 46,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHoldHint(Color accentColor) {
    /// Off to the right, where the left-aligned slots leave the screen empty.
    return Align(
      alignment: const Alignment(0.3, 0.0),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Opacity(
              opacity: 0.35 + 0.45 * _pulse.value,
              child: Transform.scale(
                scale: 0.94 + 0.10 * _pulse.value,
                child: child,
              ),
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Text always gives way to whatever the step points at: below the frame,
  /// above a gesture hint, centered when there is nothing to point at.
  Widget _buildText(Size size, Color accentColor) {
    final block = IgnorePointer(child: _textBlock(accentColor));

    switch (_step.kind) {
      case _StepKind.frame:
      case _StepKind.swipeUp:
      case _StepKind.hold:
        /// All three pointing steps share one text height, so the block stays
        /// put while the indicator below it changes.
        return Positioned(
            left: 0,
            right: 0,
            top: size.height * _kTextTopFraction,
            child: block);
      case _StepKind.plain:
        return Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Center(child: block),
          ),
        );
    }
  }

  Widget _textBlock(Color accentColor) {
    final centered = _step.kind == _StepKind.plain;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kSideMargin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            _step.title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            _bodySpan(accentColor),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w200,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _bodySpan(Color accentColor) {
    final accent = _step.accent;
    final start = accent == null ? -1 : _step.body.indexOf(accent);
    if (accent == null || start < 0) {
      return TextSpan(text: _step.body);
    }
    return TextSpan(children: [
      TextSpan(text: _step.body.substring(0, start)),
      TextSpan(
        text: accent,
        style: TextStyle(color: accentColor),
      ),
      TextSpan(text: _step.body.substring(start + accent.length)),
    ]);
  }

  Widget _buildSkip() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, _kSideMargin - 12, 0),
          child: _OverlayButton(label: 'Skip', onPressed: widget.onFinished),
        ),
      ),
    );
  }

  Widget _buildNav(bool isLast, Color accentColor) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              _kSideMargin - 12, 0, _kSideMargin - 12, 24),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: _index == 0
                    ? null
                    : _OverlayButton(label: 'Back', onPressed: _back),
              ),
              Expanded(child: Center(child: _buildDots(accentColor))),
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _OverlayButton(
                      label: isLast ? 'Done' : 'Next', onPressed: _next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots(Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: _kAnimDuration,
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _index
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}

/// The overlay is dark in both themes, so its buttons are always white.
class _OverlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OverlayButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.white),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
      ),
    );
  }
}
