part of '../main.dart';

// ---------------------------------------------------------------------------
// Basic building blocks: AppCard, animations, logo, badges, section labels.
// ---------------------------------------------------------------------------

// ============================================================================
// 10. REUSABLE WIDGETS
// ============================================================================

/// Rounded, bordered surface used everywhere instead of duplicating Cards.
/// Gives a subtle press-scale micro-interaction when tappable.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.highlight = false,
    this.color,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? color;
  final Gradient? gradient;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final dark = context.isDark;
    final base = widget.gradient != null
        ? Colors.transparent
        : (widget.color ?? context.cardColor);
    // Highlighted (currently playing / target) cards get a warm tint, a
    // thicker gold border and a soft glow so they stand out in a long list.
    final fill = widget.highlight && widget.gradient == null
        ? Color.alphaBlend(
            context.accentGold.withOpacity(dark ? 0.16 : 0.12),
            base,
          )
        : base;
    return Padding(
      padding: widget.margin,
      child: AnimatedScale(
        scale: _down && tappable ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: fill,
          clipBehavior: Clip.antiAlias,
          elevation: widget.highlight ? 4 : (dark ? 0 : 0.6),
          shadowColor: widget.highlight
              ? context.accentGold.withOpacity(0.55)
              : Colors.black26,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color:
                  widget.highlight ? context.accentGold : context.borderColor,
              width: widget.highlight ? 2.2 : 1,
            ),
          ),
          child: Ink(
            decoration: widget.gradient == null
                ? null
                : BoxDecoration(gradient: widget.gradient),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged:
                  tappable ? (v) => setState(() => _down = v) : null,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + gentle slide-up entrance. Use [delay] to stagger lists.
/// When [enabled] is false the child is shown immediately.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 14,
    this.enabled = true,
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final bool enabled;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _c = AnimationController(vsync: this, duration: total);
    final start = widget.delay.inMilliseconds / total.inMilliseconds;
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    if (widget.enabled) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps any tappable child with a subtle scale-down while pressed.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Keeps content readable on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.dark = true});
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = context.cs.primary;
    final accent = context.accentGold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, Colors.black, 0.35)!,
          ],
        ),
        border: Border.all(color: accent, width: size * 0.025),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Icon(
        Icons.menu_book_rounded,
        size: size * 0.5,
        color: accent,
      ),
    );
  }
}

class NumberBadge extends StatelessWidget {
  const NumberBadge(this.number, {super.key, this.size = 40});
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.accentGold.withOpacity(0.10),
        border: Border.all(color: context.accentGold, width: 1.3),
      ),
      child: Text(
        '$number',
        style: AppTypography.english(
          size: number > 99 ? 12 : 14,
          weight: FontWeight.w700,
          color: context.cs.primary,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: context.accentGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: AppTypography.heading(
                    size: 18, color: context.cs.onSurface),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
