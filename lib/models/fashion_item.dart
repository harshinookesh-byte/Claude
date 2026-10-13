import 'package:flutter/material.dart';

/// Where an item is worn on the model. Each slot holds at most one item.
enum Slot {
  hair('Hair', Icons.face_retouching_natural),
  dress('Dresses', Icons.checkroom),
  top('Tops', Icons.dry_cleaning),
  bottom('Bottoms', Icons.straighten),
  shoes('Shoes', Icons.ice_skating),
  necklace('Necklace', Icons.diamond_outlined),
  earrings('Earrings', Icons.blur_circular),
  headpiece('Head', Icons.auto_awesome),
  bindi('Bindi', Icons.circle),
  noseRing('Nose', Icons.radio_button_unchecked),
  bangles('Bangles', Icons.donut_large),
  bag('Bags', Icons.shopping_bag_outlined),
  glasses('Glasses', Icons.visibility_outlined);

  const Slot(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Slots that make up the main outfit (used for scoring and completeness).
  bool get isClothing => this == dress || this == top || this == bottom;

  bool get isAccessory => !isClothing && this != hair && this != shoes;
}

enum FabricPattern { plain, dots, stripes, floral, zari }

/// Theme tags used by challenges and scoring.
abstract final class Tags {
  static const indian = 'indian';
  static const wedding = 'wedding';
  static const festive = 'festive';
  static const party = 'party';
  static const redCarpet = 'redcarpet';
  static const casual = 'casual';
  static const sporty = 'sporty';
  static const office = 'office';
  static const beach = 'beach';
  static const princess = 'princess';
}

@immutable
class FashionItem {
  const FashionItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.style,
    required this.color,
    this.accent = const Color(0xFFFFD54F),
    this.pattern = FabricPattern.plain,
    this.price = 0,
    this.tags = const {},
  });

  final String id;
  final String name;
  final Slot slot;

  /// Shape key understood by the model painter (e.g. `saree`, `bun`, `jhumka`).
  final String style;
  final Color color;
  final Color accent;
  final FabricPattern pattern;

  /// Coins needed to unlock. Zero means free from the start.
  final int price;
  final Set<String> tags;

  bool get isFree => price == 0;
}
