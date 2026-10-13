import 'package:flutter/material.dart';

import 'fashion_item.dart';

/// Colour as a 32-bit ARGB int for persistence.
int _argb(Color c) =>
    ((c.a * 255).round() << 24) |
    ((c.r * 255).round() << 16) |
    ((c.g * 255).round() << 8) |
    (c.b * 255).round();

/// Face and skin settings applied in the makeup salon.
@immutable
class Makeup {
  const Makeup({
    this.skinTone = const Color(0xFFE0A87E),
    this.eyeColor = const Color(0xFF4E342E),
    this.hairColor = const Color(0xFF2B1B17),
    this.eyeshadow,
    this.lipstick,
    this.blush,
    this.eyeliner = false,
    this.lashes = false,
  });

  final Color skinTone;
  final Color eyeColor;
  final Color hairColor;
  final Color? eyeshadow;
  final Color? lipstick;
  final Color? blush;
  final bool eyeliner;
  final bool lashes;

  int get appliedCount =>
      [eyeshadow, lipstick, blush].where((c) => c != null).length +
      (eyeliner ? 1 : 0) +
      (lashes ? 1 : 0);

  Makeup copyWith({
    Color? skinTone,
    Color? eyeColor,
    Color? hairColor,
    Color? Function()? eyeshadow,
    Color? Function()? lipstick,
    Color? Function()? blush,
    bool? eyeliner,
    bool? lashes,
  }) {
    return Makeup(
      skinTone: skinTone ?? this.skinTone,
      eyeColor: eyeColor ?? this.eyeColor,
      hairColor: hairColor ?? this.hairColor,
      eyeshadow: eyeshadow != null ? eyeshadow() : this.eyeshadow,
      lipstick: lipstick != null ? lipstick() : this.lipstick,
      blush: blush != null ? blush() : this.blush,
      eyeliner: eyeliner ?? this.eyeliner,
      lashes: lashes ?? this.lashes,
    );
  }

  Map<String, dynamic> toJson() => {
        'skin': _argb(skinTone),
        'eye': _argb(eyeColor),
        'hair': _argb(hairColor),
        'shadow': eyeshadow == null ? null : _argb(eyeshadow!),
        'lips': lipstick == null ? null : _argb(lipstick!),
        'blush': blush == null ? null : _argb(blush!),
        'liner': eyeliner,
        'lashes': lashes,
      };

  factory Makeup.fromJson(Map<String, dynamic> j) {
    Color? c(Object? v) => v == null ? null : Color(v as int);
    return Makeup(
      skinTone: c(j['skin']) ?? const Makeup().skinTone,
      eyeColor: c(j['eye']) ?? const Makeup().eyeColor,
      hairColor: c(j['hair']) ?? const Makeup().hairColor,
      eyeshadow: c(j['shadow']),
      lipstick: c(j['lips']),
      blush: c(j['blush']),
      eyeliner: j['liner'] as bool? ?? false,
      lashes: j['lashes'] as bool? ?? false,
    );
  }
}

/// A complete styled look: makeup plus one item id per occupied slot.
@immutable
class Look {
  const Look({this.makeup = const Makeup(), this.items = const {}});

  final Makeup makeup;
  final Map<Slot, String> items;

  String? operator [](Slot slot) => items[slot];

  /// Equips [item], keeping the outfit consistent: a dress replaces any
  /// top/bottom and vice versa. Equipping an already-worn item removes it.
  Look toggle(FashionItem item) {
    final next = Map<Slot, String>.from(items);
    if (next[item.slot] == item.id) {
      next.remove(item.slot);
      return Look(makeup: makeup, items: next);
    }
    next[item.slot] = item.id;
    if (item.slot == Slot.dress) {
      next.remove(Slot.top);
      next.remove(Slot.bottom);
    } else if (item.slot == Slot.top || item.slot == Slot.bottom) {
      next.remove(Slot.dress);
    }
    return Look(makeup: makeup, items: next);
  }

  Look clear(Slot slot) =>
      Look(makeup: makeup, items: Map.of(items)..remove(slot));

  Look withMakeup(Makeup m) => Look(makeup: m, items: items);

  bool get hasOutfit =>
      items.containsKey(Slot.dress) ||
      (items.containsKey(Slot.top) && items.containsKey(Slot.bottom));

  Map<String, dynamic> toJson() => {
        'makeup': makeup.toJson(),
        'items': {for (final e in items.entries) e.key.name: e.value},
      };

  factory Look.fromJson(Map<String, dynamic> j) {
    final raw = (j['items'] as Map?)?.cast<String, dynamic>() ?? {};
    final items = <Slot, String>{};
    for (final e in raw.entries) {
      final slot = Slot.values.where((s) => s.name == e.key).firstOrNull;
      if (slot != null) items[slot] = e.value as String;
    }
    return Look(
      makeup: Makeup.fromJson(
          (j['makeup'] as Map?)?.cast<String, dynamic>() ?? const {}),
      items: items,
    );
  }
}

/// A look the player saved to their gallery.
@immutable
class SavedLook {
  const SavedLook({
    required this.look,
    required this.title,
    required this.createdAt,
    this.score,
  });

  final Look look;
  final String title;
  final DateTime createdAt;
  final int? score;

  Map<String, dynamic> toJson() => {
        'look': look.toJson(),
        'title': title,
        'at': createdAt.millisecondsSinceEpoch,
        'score': score,
      };

  factory SavedLook.fromJson(Map<String, dynamic> j) => SavedLook(
        look: Look.fromJson((j['look'] as Map).cast<String, dynamic>()),
        title: j['title'] as String? ?? 'My Look',
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['at'] as int? ?? 0),
        score: j['score'] as int?,
      );
}
