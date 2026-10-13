import 'package:flutter/material.dart';

import '../models/fashion_item.dart';

/// A themed fashion-show round the player competes in.
@immutable
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.brief,
    required this.tags,
    required this.gradient,
    required this.icon,
    required this.unlockLevel,
    this.boldMakeup = false,
  });

  final String id;
  final String title;
  final String brief;

  /// The judges reward items carrying any of these tags.
  final Set<String> tags;
  final List<Color> gradient;
  final IconData icon;
  final int unlockLevel;

  /// Whether the judges expect full glam makeup.
  final bool boldMakeup;

  int get reward => 80 + unlockLevel * 20;
}

const challenges = <Challenge>[
  Challenge(
    id: 'street',
    title: 'Street Style',
    brief: 'Comfy, cool and camera-ready for a day in the city.',
    tags: {Tags.casual, Tags.sporty},
    gradient: [Color(0xFF42A5F5), Color(0xFF80DEEA)],
    icon: Icons.location_city,
    unlockLevel: 1,
  ),
  Challenge(
    id: 'mehendi',
    title: 'Mehendi Night',
    brief: 'Bright festive colours, flowers in the hair and lots of bangles!',
    tags: {Tags.indian, Tags.festive},
    gradient: [Color(0xFF66BB6A), Color(0xFFFFEE58)],
    icon: Icons.local_florist,
    unlockLevel: 1,
  ),
  Challenge(
    id: 'beach',
    title: 'Beach Holiday',
    brief: 'Sun, sand and breezy looks for a seaside escape.',
    tags: {Tags.beach, Tags.casual},
    gradient: [Color(0xFF26C6DA), Color(0xFFFFE082)],
    icon: Icons.beach_access,
    unlockLevel: 2,
  ),
  Challenge(
    id: 'office',
    title: 'Boss Lady',
    brief: 'Polished and powerful for a big day at the office.',
    tags: {Tags.office},
    gradient: [Color(0xFF78909C), Color(0xFFCFD8DC)],
    icon: Icons.work_outline,
    unlockLevel: 2,
  ),
  Challenge(
    id: 'diwali',
    title: 'Diwali Festival',
    brief: 'Shine like a diya! Rich silks, gold jewellery and festive glam.',
    tags: {Tags.indian, Tags.festive, Tags.party},
    gradient: [Color(0xFFFF7043), Color(0xFFFFCA28)],
    icon: Icons.light_mode,
    unlockLevel: 3,
    boldMakeup: true,
  ),
  Challenge(
    id: 'party',
    title: 'Glitter Party',
    brief: 'Sparkle all night on the dance floor.',
    tags: {Tags.party},
    gradient: [Color(0xFFAB47BC), Color(0xFFEC407A)],
    icon: Icons.nightlife,
    unlockLevel: 3,
    boldMakeup: true,
  ),
  Challenge(
    id: 'wedding',
    title: 'Royal Indian Wedding',
    brief: 'Dress the bride! Lehenga or saree, kundan, tikka and nath.',
    tags: {Tags.indian, Tags.wedding},
    gradient: [Color(0xFFC62828), Color(0xFFFFB300)],
    icon: Icons.favorite,
    unlockLevel: 4,
    boldMakeup: true,
  ),
  Challenge(
    id: 'redcarpet',
    title: 'Red Carpet Gala',
    brief: 'All eyes on you - flawless gowns and Hollywood glamour.',
    tags: {Tags.redCarpet},
    gradient: [Color(0xFF880E4F), Color(0xFFE53935)],
    icon: Icons.star,
    unlockLevel: 5,
    boldMakeup: true,
  ),
  Challenge(
    id: 'princess',
    title: 'Princess Ball',
    brief: 'A fairytale evening at the palace.',
    tags: {Tags.princess},
    gradient: [Color(0xFF7E57C2), Color(0xFF90CAF9)],
    icon: Icons.castle,
    unlockLevel: 6,
  ),
];

const opponentNames = [
  'Aisha',
  'Priya',
  'Mia',
  'Zara',
  'Ananya',
  'Chloe',
  'Riya',
  'Sofia',
  'Kavya',
  'Lily',
  'Meera',
  'Emma',
];
