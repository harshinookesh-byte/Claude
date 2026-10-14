import 'package:flutter/material.dart';

import '../models/look.dart';
import '../state/game_state.dart';
import '../theme/tokens.dart';
import 'model_painter.dart';

/// The model, standing on a flat floor mark one tone step above the ground.
/// When [crossfade] is on, a change of look dissolves rather than jumps:
/// the model stays put while the outfit changes.
class ModelView extends StatelessWidget {
  const ModelView({
    super.key,
    required this.look,
    this.showFloor = true,
    this.crossfade = false,
  });

  final Look look;
  final bool showFloor;
  final bool crossfade;

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      key: crossfade ? ValueKey(look) : null,
      child: CustomPaint(painter: ModelPainter(look)),
    );
    return AspectRatio(
      aspectRatio: 0.5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showFloor)
            const Align(
              alignment: Alignment(0, 0.985),
              child: FractionallySizedBox(
                widthFactor: 0.7,
                heightFactor: 0.035,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Palette.surface,
                    shape: StadiumBorder(),
                  ),
                ),
              ),
            ),
          if (crossfade && !reduceMotion(context))
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              // Fill the frame; the default layout would size the painter
              // to nothing.
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: paint,
            )
          else
            paint,
        ],
      ),
    );
  }
}

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

String formatCoins(int coins) {
  final s = coins.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// The player's coins, as words.
class CoinCount extends StatelessWidget {
  const CoinCount({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Text(
      '${formatCoins(game.coins)} coins',
      style: Txt.bodyMedium().copyWith(fontFeatures: Txt.tabular),
    );
  }
}

/// Scales down a touch while pressed, so every control answers the thumb.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down && !reduceMotion(context) ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The one primary action on a screen: flat accent, square, named for what
/// it does.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          color: enabled ? Palette.accent : Palette.raised,
          child: Text(
            label,
            style: Txt.lead(enabled ? Palette.accentInk : Palette.muted),
          ),
        ),
      ),
    );
  }
}

/// A plain text link with a thumb-sized target.
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Pressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Txt.body(onTap == null ? Palette.muted : Palette.ink)
                  .copyWith(
                decoration: onTap == null ? null : TextDecoration.underline,
                decorationColor: Palette.ink,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A square icon control on a surface tile; no shadow, no circle.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Pressable(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            color: Palette.surface,
            child:
                Icon(icon, color: onTap == null ? Palette.raised : Palette.ink),
          ),
        ),
      ),
    );
  }
}

/// A row of text tabs. The selected one is filled with the accent.
class TextTabs<T> extends StatelessWidget {
  const TextTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.marked,
    this.scrollable = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  /// Tabs that hold something (e.g. a slot with an item worn) get a dot.
  final bool Function(T)? marked;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final v in values)
        _Tab(
          label: label(v),
          selected: v == selected,
          marked: marked?.call(v) ?? false,
          expand: !scrollable,
          onTap: () => onSelect(v),
        ),
    ];
    if (!scrollable) return Row(children: tabs);
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kMargin - 8),
      children: tabs,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.marked,
    required this.expand,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool marked;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Palette.accentInk : Palette.ink;
    final tab = Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          color: selected ? Palette.accent : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Txt.body(fg)),
              if (marked) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return expand ? Expanded(child: tab) : tab;
  }
}

/// The plain bar at the top of an inner screen: back, title, coins.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.showCoins = true});

  final String title;
  final bool showCoins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Txt.lead()),
          ),
          if (showCoins) const CoinCount(),
          const SizedBox(width: kMargin),
        ],
      ),
    );
  }
}

/// Fades and lifts [child] in once, [index] steps after the screen opens,
/// so a screen's parts arrive in reading order. Content is never left
/// hidden: with reduced motion it simply appears.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = 70 * index;
    final total = 380 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Level progress as a solid bar: the filled part in the accent.
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final points = (game.levelProgress * GameState.xpPerLevel).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Level ${game.level}', style: Txt.head()),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$points of ${GameState.xpPerLevel} points',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Txt.small().copyWith(fontFeatures: Txt.tabular)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 8,
          child: LinearProgressIndicator(value: game.levelProgress),
        ),
      ],
    );
  }
}
