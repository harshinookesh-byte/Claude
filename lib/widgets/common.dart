import 'package:flutter/material.dart';

import '../models/look.dart';
import '../state/game_state.dart';
import 'model_painter.dart';

const pinkGradient = [Color(0xFFFF6FB5), Color(0xFFB06BFF)];

/// The model standing on a little spotlight stage.
class ModelView extends StatelessWidget {
  const ModelView({super.key, required this.look, this.showStage = true});

  final Look look;
  final bool showStage;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showStage)
            const Align(
              alignment: Alignment(0, 0.98),
              child: FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.06,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x55000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
          RepaintBoundary(child: CustomPaint(painter: ModelPainter(look))),
        ],
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return _Pill(
      icon:
          const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 20),
      label: '${game.coins}',
    );
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return _Pill(
      icon: const Icon(Icons.star_rounded, color: Color(0xFFFF4081), size: 20),
      label: 'Lv ${game.level}',
      trailing: SizedBox(
        width: 46,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: game.levelProgress,
            minHeight: 6,
            backgroundColor: Colors.pink.shade50,
            color: const Color(0xFFFF4081),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.trailing});

  final Widget icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF5B2A86))),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

/// Big rounded call-to-action button with a gradient fill.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors = pinkGradient,
    this.height = 56,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: colors.first.withAlpha(120),
        child: Ink(
          height: height,
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudioBackground extends StatelessWidget {
  const StudioBackground({super.key, required this.child, this.colors});

  /// Colour at the bottom of the default gradient; screens use it behind the
  /// banner / navigation-bar area so it blends with the page.
  static const bottomColor = Color(0xFFE9D7FF);

  final Widget child;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? const [Color(0xFFFFE1F0), bottomColor],
        ),
      ),
      child: child,
    );
  }
}
