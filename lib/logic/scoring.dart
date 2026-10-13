import 'dart:math' as math;

import '../data/catalog.dart';
import '../data/challenges.dart';
import '../models/fashion_item.dart';
import '../models/look.dart';

/// Breakdown of how the judges rated a look, each part out of its max.
class ScoreCard {
  const ScoreCard(
      {required this.theme, required this.style, required this.makeup});

  /// Out of 50: how well the items fit the challenge theme.
  final double theme;

  /// Out of 30: outfit completeness and accessorising.
  final double style;

  /// Out of 20: makeup effort, weighted by the theme's glam level.
  final double makeup;

  int get total => (theme + style + makeup).round().clamp(0, 100);

  /// Three judges' marks out of 10, one per category.
  List<int> get judgeMarks => [
        (theme / 5).round().clamp(1, 10),
        (style / 3).round().clamp(1, 10),
        (makeup / 2).round().clamp(1, 10),
      ];
}

ScoreCard scoreLook(Look look, Challenge challenge) {
  final items =
      look.items.values.map(itemById).whereType<FashionItem>().toList();

  // Theme: share of worn items matching the brief. The main outfit counts
  // triple so a themed dress matters more than a themed bracelet.
  var weight = 0.0, matched = 0.0;
  for (final it in items) {
    final w = it.slot.isClothing ? 3.0 : 1.0;
    weight += w;
    final hits = it.tags.intersection(challenge.tags).length;
    if (hits > 0) matched += w * math.min(1.0, 0.75 + 0.25 * hits);
  }
  // Need a few themed pieces to earn full theme marks.
  final coverage = math.min(1.0, weight / 8);
  final theme =
      weight == 0 ? 0.0 : 50 * (matched / weight) * (0.4 + 0.6 * coverage);

  // Style: a complete, accessorised look.
  var style = 0.0;
  if (look.hasOutfit) style += 12;
  if (look[Slot.shoes] != null) style += 6;
  if (look[Slot.hair] != null) style += 4;
  final accessories = items.where((i) => i.slot.isAccessory).length;
  style += math.min(accessories, 4) * 2;

  // Makeup: glam themes want the full face, casual ones a lighter touch.
  final m = look.makeup;
  final applied = m.appliedCount; // 0..5
  final ideal = challenge.boldMakeup ? 5 : 3;
  final makeup = applied >= ideal ? 20.0 : 20.0 * applied / ideal;

  return ScoreCard(theme: theme, style: style, makeup: makeup.toDouble());
}

/// Builds a rival look for [challenge]. Higher [skill] means the rival picks
/// on-theme items more often.
Look rivalLook(Challenge challenge, math.Random rnd, {double skill = 0.6}) {
  FashionItem? pick(Slot slot) {
    final all = itemsFor(slot);
    if (all.isEmpty) return null;
    final themed =
        all.where((i) => i.tags.any(challenge.tags.contains)).toList();
    final pool = themed.isNotEmpty && rnd.nextDouble() < skill ? themed : all;
    return pool[rnd.nextInt(pool.length)];
  }

  var look = Look(
    makeup: Makeup(
      skinTone: skinTones[rnd.nextInt(skinTones.length)],
      hairColor: hairColors[rnd.nextInt(5)],
      eyeColor: eyeColors[rnd.nextInt(eyeColors.length)],
      lipstick: rnd.nextDouble() < skill + 0.2
          ? lipstickColors[rnd.nextInt(lipstickColors.length)]
          : null,
      eyeshadow: rnd.nextDouble() < skill
          ? eyeshadowColors[rnd.nextInt(eyeshadowColors.length)]
          : null,
      blush: rnd.nextDouble() < skill
          ? blushColors[rnd.nextInt(blushColors.length)]
          : null,
      eyeliner: rnd.nextDouble() < skill,
      lashes: rnd.nextDouble() < skill,
    ),
  );

  final slots = <Slot>[Slot.hair, Slot.shoes];
  if (rnd.nextBool()) {
    slots.add(Slot.dress);
  } else {
    slots.addAll([Slot.top, Slot.bottom]);
  }
  for (final s in Slot.values.where((s) => s.isAccessory)) {
    if (rnd.nextDouble() < 0.25 + skill * 0.3) slots.add(s);
  }
  for (final s in slots) {
    final it = pick(s);
    if (it != null) look = look.toggle(it);
  }
  return look;
}
