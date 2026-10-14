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
    required this.unlockLevel,
    this.boldMakeup = false,
  });

  final String id;
  final String title;
  final String brief;

  /// The judges reward items carrying any of these tags.
  final Set<String> tags;
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
    unlockLevel: 1,
  ),
  Challenge(
    id: 'mehendi',
    title: 'Mehendi Night',
    brief: 'Bright festive colours, flowers in the hair and stacks of bangles.',
    tags: {Tags.indian, Tags.festive},
    unlockLevel: 1,
  ),
  Challenge(
    id: 'beach',
    title: 'Beach Holiday',
    brief: 'Sun, sand and breezy looks for a seaside escape.',
    tags: {Tags.beach, Tags.casual},
    unlockLevel: 2,
  ),
  Challenge(
    id: 'office',
    title: 'Boss Lady',
    brief: 'Polished and powerful for a big day at the office.',
    tags: {Tags.office},
    unlockLevel: 2,
  ),
  Challenge(
    id: 'diwali',
    title: 'Diwali Festival',
    brief: 'Rich silks, gold jewellery and festive glam, bright as a diya.',
    tags: {Tags.indian, Tags.festive, Tags.party},
    unlockLevel: 3,
    boldMakeup: true,
  ),
  Challenge(
    id: 'party',
    title: 'Glitter Party',
    brief: 'Sparkle all night on the dance floor.',
    tags: {Tags.party},
    unlockLevel: 3,
    boldMakeup: true,
  ),
  Challenge(
    id: 'wedding',
    title: 'Royal Indian Wedding',
    brief: 'Dress the bride: lehenga or saree, kundan, tikka and nath.',
    tags: {Tags.indian, Tags.wedding},
    unlockLevel: 4,
    boldMakeup: true,
  ),
  Challenge(
    id: 'redcarpet',
    title: 'Red Carpet Gala',
    brief:
        'Floor-length gowns and old Hollywood glamour, with every camera on you.',
    tags: {Tags.redCarpet},
    unlockLevel: 5,
    boldMakeup: true,
  ),
  Challenge(
    id: 'princess',
    title: 'Princess Ball',
    brief: 'A fairytale evening at the palace.',
    tags: {Tags.princess},
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
