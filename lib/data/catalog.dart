import 'package:flutter/material.dart';

import '../models/fashion_item.dart';

/// Every wearable item in the game, built from a set of base designs that
/// come in several colourways.
final List<FashionItem> catalog = _buildCatalog();

final Map<String, FashionItem> _byId = {for (final i in catalog) i.id: i};

FashionItem? itemById(String? id) => id == null ? null : _byId[id];

List<FashionItem> itemsFor(Slot slot) =>
    catalog.where((i) => i.slot == slot).toList(growable: false);

class _Design {
  const _Design(this.style, this.name, this.slot, this.tags, this.colorways,
      {this.pattern = FabricPattern.plain, this.price = 0});

  final String style;
  final String name;
  final Slot slot;
  final Set<String> tags;

  /// (colour name, main colour, accent colour)
  final List<(String, Color, Color)> colorways;
  final FabricPattern pattern;
  final int price;
}

const _gold = Color(0xFFFFC94A);
const _silver = Color(0xFFE0E0E0);

const _designs = <_Design>[
  // ---------- Dresses ----------
  _Design(
      'saree',
      'Silk Saree',
      Slot.dress,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Ruby', Color(0xFFC2185B), _gold),
        ('Emerald', Color(0xFF00897B), _gold),
        ('Royal', Color(0xFF3949AB), _silver),
        ('Marigold', Color(0xFFFFA000), Color(0xFFD81B60)),
      ],
      pattern: FabricPattern.zari),
  _Design(
      'saree',
      'Chiffon Saree',
      Slot.dress,
      {Tags.indian, Tags.party},
      [
        ('Blush', Color(0xFFF8BBD0), Color(0xFFAD1457)),
        ('Mint', Color(0xFFA5D6A7), Color(0xFF2E7D32)),
      ],
      pattern: FabricPattern.floral,
      price: 150),
  _Design(
      'lehenga',
      'Bridal Lehenga',
      Slot.dress,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Crimson', Color(0xFFB71C1C), _gold),
        ('Wine', Color(0xFF880E4F), _gold),
        ('Peach', Color(0xFFFFAB91), Color(0xFFAD1457)),
      ],
      pattern: FabricPattern.zari,
      price: 300),
  _Design(
      'anarkali',
      'Anarkali Suit',
      Slot.dress,
      {Tags.indian, Tags.festive, Tags.party},
      [
        ('Teal', Color(0xFF00838F), _gold),
        ('Lilac', Color(0xFFBA68C8), Color(0xFFFFF59D)),
        ('Mustard', Color(0xFFF9A825), Color(0xFF6A1B9A)),
      ],
      pattern: FabricPattern.floral,
      price: 120),
  _Design(
      'salwar',
      'Salwar Kameez',
      Slot.dress,
      {Tags.indian, Tags.casual, Tags.festive},
      [
        ('Sky', Color(0xFF4FC3F7), Color(0xFFFFFFFF)),
        ('Rose', Color(0xFFF06292), Color(0xFFFFF176)),
        ('Leaf', Color(0xFF7CB342), Color(0xFFFFEB3B)),
      ],
      pattern: FabricPattern.dots),
  _Design(
      'gown',
      'Evening Gown',
      Slot.dress,
      {Tags.redCarpet, Tags.party},
      [
        ('Midnight', Color(0xFF1A237E), _silver),
        ('Scarlet', Color(0xFFD50000), _gold),
        ('Champagne', Color(0xFFF3D9B1), _gold),
        ('Noir', Color(0xFF212121), _silver),
      ],
      price: 200),
  _Design(
      'ballgown',
      'Princess Ball Gown',
      Slot.dress,
      {Tags.princess, Tags.party, Tags.wedding},
      [
        ('Pearl', Color(0xFFFFFFFF), Color(0xFFB3E5FC)),
        ('Aurora', Color(0xFFF48FB1), Color(0xFFFFFFFF)),
        ('Frost', Color(0xFF90CAF9), _silver),
      ],
      pattern: FabricPattern.dots,
      price: 250),
  _Design('minidress', 'Party Mini Dress', Slot.dress, {
    Tags.party,
    Tags.casual
  }, [
    ('Hot Pink', Color(0xFFE91E63), Color(0xFF000000)),
    ('Sequin', Color(0xFF9E9E9E), _silver),
    ('Sunny', Color(0xFFFFEB3B), Color(0xFFFF7043)),
  ]),
  _Design(
      'sundress',
      'Floral Sundress',
      Slot.dress,
      {Tags.beach, Tags.casual},
      [
        ('Daisy', Color(0xFFFFF9C4), Color(0xFFFF8A65)),
        ('Ocean', Color(0xFF80DEEA), Color(0xFFFFFFFF)),
      ],
      pattern: FabricPattern.floral),
  _Design(
      'jumpsuit',
      'Track Jumpsuit',
      Slot.dress,
      {Tags.sporty, Tags.casual},
      [
        ('Coral', Color(0xFFFF7043), Color(0xFFFFFFFF)),
        ('Black', Color(0xFF263238), Color(0xFF76FF03)),
      ],
      pattern: FabricPattern.stripes),

  // ---------- Tops ----------
  _Design('tee', 'Basic Tee', Slot.top, {
    Tags.casual,
    Tags.sporty
  }, [
    ('White', Color(0xFFFAFAFA), Color(0xFF9E9E9E)),
    ('Pink', Color(0xFFF48FB1), Color(0xFFFFFFFF)),
    ('Navy', Color(0xFF283593), Color(0xFFFFFFFF)),
  ]),
  _Design(
      'crop',
      'Crop Top',
      Slot.top,
      {Tags.party, Tags.beach, Tags.casual},
      [
        ('Lime', Color(0xFFC6FF00), Color(0xFF000000)),
        ('Lavender', Color(0xFFB39DDB), Color(0xFFFFFFFF)),
        ('Stripe', Color(0xFFFFFFFF), Color(0xFFE53935)),
      ],
      pattern: FabricPattern.stripes),
  _Design(
      'choli',
      'Embroidered Choli',
      Slot.top,
      {Tags.indian, Tags.festive, Tags.wedding},
      [
        ('Gold', Color(0xFFFFB300), Color(0xFFC62828)),
        ('Magenta', Color(0xFFD81B60), _gold),
      ],
      pattern: FabricPattern.zari,
      price: 80),
  _Design(
      'kurti',
      'Printed Kurti',
      Slot.top,
      {Tags.indian, Tags.casual, Tags.office},
      [
        ('Indigo', Color(0xFF3F51B5), Color(0xFFFFFFFF)),
        ('Saffron', Color(0xFFFF8F00), Color(0xFF4E342E)),
        ('Blossom', Color(0xFFF8BBD0), Color(0xFF00897B)),
      ],
      pattern: FabricPattern.floral),
  _Design(
      'blazer',
      'Tailored Blazer',
      Slot.top,
      {Tags.office},
      [
        ('Charcoal', Color(0xFF424242), Color(0xFFEEEEEE)),
        ('Camel', Color(0xFFBC8F5F), Color(0xFFFFFFFF)),
        ('Blush', Color(0xFFF4C2C2), Color(0xFFFFFFFF)),
      ],
      price: 100),
  _Design('hoodie', 'Cozy Hoodie', Slot.top, {
    Tags.sporty,
    Tags.casual
  }, [
    ('Grey', Color(0xFFB0BEC5), Color(0xFF455A64)),
    ('Mint', Color(0xFF80CBC4), Color(0xFFFFFFFF)),
  ]),
  _Design(
      'tank',
      'Silk Cami',
      Slot.top,
      {Tags.party, Tags.beach},
      [
        ('Ivory', Color(0xFFFFF8E1), _gold),
        ('Ruby', Color(0xFFAD1457), _gold),
      ],
      price: 60),

  // ---------- Bottoms ----------
  _Design('jeans', 'Skinny Jeans', Slot.bottom, {
    Tags.casual
  }, [
    ('Denim', Color(0xFF5C7FB0), Color(0xFFFFCA28)),
    ('Black', Color(0xFF37474F), Color(0xFFB0BEC5)),
    ('White', Color(0xFFF5F5F5), Color(0xFFBDBDBD)),
  ]),
  _Design('shorts', 'Denim Shorts', Slot.bottom, {
    Tags.beach,
    Tags.casual,
    Tags.sporty
  }, [
    ('Light', Color(0xFF90A4C8), Color(0xFFFFFFFF)),
    ('Pink', Color(0xFFF48FB1), Color(0xFFFFFFFF)),
  ]),
  _Design(
      'miniskirt',
      'Pleated Mini Skirt',
      Slot.bottom,
      {Tags.party, Tags.casual},
      [
        ('Plaid', Color(0xFFC62828), Color(0xFF212121)),
        ('Black', Color(0xFF212121), Color(0xFF757575)),
      ],
      pattern: FabricPattern.stripes),
  _Design(
      'pencil',
      'Pencil Skirt',
      Slot.bottom,
      {Tags.office},
      [
        ('Black', Color(0xFF263238), Color(0xFF90A4AE)),
        ('Wine', Color(0xFF6D1B3A), Color(0xFFFFFFFF)),
      ],
      price: 60),
  _Design(
      'lehengaskirt',
      'Lehenga Skirt',
      Slot.bottom,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Rani Pink', Color(0xFFE91E63), _gold),
        ('Royal Blue', Color(0xFF1565C0), _gold),
        ('Ivory', Color(0xFFFFF8E1), Color(0xFFC62828)),
      ],
      pattern: FabricPattern.zari,
      price: 150),
  _Design('palazzo', 'Palazzo Pants', Slot.bottom, {
    Tags.indian,
    Tags.casual,
    Tags.office
  }, [
    ('White', Color(0xFFFAFAFA), Color(0xFFBDBDBD)),
    ('Mustard', Color(0xFFFBC02D), Color(0xFF6D4C41)),
  ]),
  _Design('leggings', 'Churidar', Slot.bottom, {
    Tags.indian,
    Tags.sporty,
    Tags.casual
  }, [
    ('White', Color(0xFFF5F5F5), Color(0xFFBDBDBD)),
    ('Black', Color(0xFF212121), Color(0xFF616161)),
    ('Maroon', Color(0xFF7B1F2B), Color(0xFFFFCA28)),
  ]),

  // ---------- Shoes ----------
  _Design('heels', 'Stiletto Heels', Slot.shoes, {
    Tags.party,
    Tags.redCarpet,
    Tags.office
  }, [
    ('Nude', Color(0xFFD7B19D), _gold),
    ('Red', Color(0xFFD50000), _gold),
    ('Black', Color(0xFF212121), _silver),
  ]),
  _Design(
      'jutti',
      'Embroidered Jutti',
      Slot.shoes,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Gold', Color(0xFFFFB300), Color(0xFFC62828)),
        ('Maroon', Color(0xFF880E4F), _gold),
      ],
      price: 50),
  _Design('sneakers', 'Sneakers', Slot.shoes, {
    Tags.sporty,
    Tags.casual
  }, [
    ('White', Color(0xFFFAFAFA), Color(0xFFE91E63)),
    ('Neon', Color(0xFF76FF03), Color(0xFF212121)),
  ]),
  _Design('sandals', 'Flat Sandals', Slot.shoes, {
    Tags.beach,
    Tags.casual,
    Tags.indian
  }, [
    ('Tan', Color(0xFFBC8F5F), _gold),
    ('Pink', Color(0xFFF06292), Color(0xFFFFFFFF)),
  ]),
  _Design(
      'boots',
      'Knee Boots',
      Slot.shoes,
      {Tags.party, Tags.casual, Tags.redCarpet},
      [
        ('Brown', Color(0xFF5D4037), _gold),
        ('Black', Color(0xFF212121), _silver),
      ],
      price: 90),
  _Design(
      'glassslipper',
      'Glass Slippers',
      Slot.shoes,
      {Tags.princess, Tags.wedding},
      [
        ('Crystal', Color(0xFFB3E5FC), Color(0xFFFFFFFF)),
      ],
      price: 120),

  // ---------- Hair (colour comes from makeup.hairColor) ----------
  _Design('long', 'Long & Sleek', Slot.hair,
      {Tags.casual, Tags.office, Tags.redCarpet}, [('', Colors.brown, _gold)]),
  _Design('wavy', 'Glam Waves', Slot.hair,
      {Tags.redCarpet, Tags.party, Tags.princess}, [('', Colors.brown, _gold)]),
  _Design(
      'bun',
      'Bridal Bun',
      Slot.hair,
      {Tags.indian, Tags.wedding, Tags.office},
      [('', Colors.brown, Color(0xFFFFFFFF))]),
  _Design('braid', 'Side Braid', Slot.hair,
      {Tags.indian, Tags.festive, Tags.casual}, [('', Colors.brown, _gold)]),
  _Design('ponytail', 'High Ponytail', Slot.hair,
      {Tags.sporty, Tags.casual, Tags.beach}, [('', Colors.brown, _gold)]),
  _Design('bob', 'Curly Bob', Slot.hair, {Tags.party, Tags.casual},
      [('', Colors.brown, _gold)],
      price: 80),
  _Design(
      'updo',
      'Princess Updo',
      Slot.hair,
      {Tags.princess, Tags.wedding, Tags.redCarpet},
      [('', Colors.brown, _gold)],
      price: 120),

  // ---------- Jewellery & accessories ----------
  _Design(
      'kundan',
      'Kundan Choker',
      Slot.necklace,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Emerald', _gold, Color(0xFF00C853)),
        ('Ruby', _gold, Color(0xFFD50000)),
      ],
      price: 100),
  _Design(
      'pearl',
      'Pearl Strand',
      Slot.necklace,
      {Tags.office, Tags.redCarpet, Tags.princess},
      [('White', Color(0xFFFFFDE7), Color(0xFFFFFFFF))]),
  _Design('pendant', 'Heart Pendant', Slot.necklace, {
    Tags.casual,
    Tags.party,
    Tags.beach
  }, [
    ('Gold', _gold, Color(0xFFE91E63)),
    ('Silver', _silver, Color(0xFF29B6F6)),
  ]),
  _Design('jhumka', 'Jhumka', Slot.earrings, {
    Tags.indian,
    Tags.festive,
    Tags.wedding
  }, [
    ('Gold', _gold, Color(0xFFD50000)),
    ('Oxidised', Color(0xFF9E9E9E), Color(0xFF26A69A)),
  ]),
  _Design(
      'hoops',
      'Hoop Earrings',
      Slot.earrings,
      {Tags.casual, Tags.party, Tags.beach},
      [('Gold', _gold, _gold), ('Silver', _silver, _silver)]),
  _Design(
      'studs',
      'Diamond Studs',
      Slot.earrings,
      {Tags.office, Tags.redCarpet, Tags.princess},
      [('Diamond', Color(0xFFE1F5FE), Color(0xFFFFFFFF))],
      price: 70),
  _Design(
      'tikka',
      'Maang Tikka',
      Slot.headpiece,
      {Tags.indian, Tags.wedding, Tags.festive},
      [
        ('Ruby', _gold, Color(0xFFD50000)),
        ('Pearl', _gold, Color(0xFFFFFFFF)),
      ],
      price: 60),
  _Design(
      'tiara',
      'Crystal Tiara',
      Slot.headpiece,
      {Tags.princess, Tags.wedding, Tags.redCarpet},
      [('Silver', _silver, Color(0xFF81D4FA))],
      price: 150),
  _Design('flowers', 'Gajra Flowers', Slot.headpiece, {
    Tags.indian,
    Tags.festive,
    Tags.beach
  }, [
    ('Jasmine', Color(0xFFFFFFFF), Color(0xFFFFEB3B)),
    ('Rose', Color(0xFFE91E63), Color(0xFF43A047)),
  ]),
  _Design('headband', 'Satin Headband', Slot.headpiece, {
    Tags.casual,
    Tags.office,
    Tags.sporty
  }, [
    ('Black', Color(0xFF212121), Color(0xFF616161)),
    ('Pink', Color(0xFFF48FB1), Color(0xFFFFFFFF)),
  ]),
  _Design('dot', 'Classic Bindi', Slot.bindi, {
    Tags.indian,
    Tags.wedding,
    Tags.festive
  }, [
    ('Red', Color(0xFFD50000), _gold),
    ('Maroon', Color(0xFF6A1B1A), _gold),
  ]),
  _Design(
      'jewel',
      'Jewelled Bindi',
      Slot.bindi,
      {Tags.indian, Tags.wedding, Tags.party},
      [('Crystal', Color(0xFFE91E63), _gold)],
      price: 30),
  _Design('nath', 'Bridal Nath', Slot.noseRing, {Tags.indian, Tags.wedding},
      [('Gold', _gold, Color(0xFFD50000))],
      price: 80),
  _Design(
      'nosestud',
      'Nose Pin',
      Slot.noseRing,
      {Tags.indian, Tags.casual, Tags.festive},
      [('Diamond', Color(0xFFE1F5FE), _gold)]),
  _Design('bangles', 'Glass Bangles', Slot.bangles, {
    Tags.indian,
    Tags.festive,
    Tags.wedding
  }, [
    ('Red & Gold', Color(0xFFD50000), _gold),
    ('Green', Color(0xFF2E7D32), _gold),
  ]),
  _Design(
      'bracelet',
      'Charm Bracelet',
      Slot.bangles,
      {Tags.casual, Tags.party, Tags.office},
      [('Silver', _silver, Color(0xFFE91E63))]),
  _Design(
      'clutch',
      'Sequin Clutch',
      Slot.bag,
      {Tags.party, Tags.redCarpet, Tags.wedding},
      [('Gold', _gold, _silver), ('Silver', _silver, _gold)],
      price: 70),
  _Design(
      'potli',
      'Potli Bag',
      Slot.bag,
      {Tags.indian, Tags.wedding, Tags.festive},
      [('Velvet', Color(0xFF880E4F), _gold)],
      price: 50),
  _Design(
      'tote',
      'Canvas Tote',
      Slot.bag,
      {Tags.casual, Tags.beach, Tags.office},
      [('Natural', Color(0xFFE6D3B3), Color(0xFF6D4C41))]),
  _Design('sunglasses', 'Cat-Eye Shades', Slot.glasses, {
    Tags.beach,
    Tags.casual,
    Tags.party
  }, [
    ('Black', Color(0xFF212121), _gold),
    ('Pink', Color(0xFFE91E63), _gold)
  ]),
  _Design('specs', 'Smart Specs', Slot.glasses, {Tags.office},
      [('Tortoise', Color(0xFF6D4C41), Color(0xFFBCAAA4))]),
];

List<FashionItem> _buildCatalog() {
  final items = <FashionItem>[];
  for (final d in _designs) {
    for (var i = 0; i < d.colorways.length; i++) {
      final (colorName, color, accent) = d.colorways[i];
      // Alternate colourways of paid designs cost a little more.
      final price = d.price == 0 ? 0 : d.price + i * 20;
      items.add(FashionItem(
        // Ids are persisted in saved looks, so they must be stable.
        id: '${d.slot.name}_${_slug(d.name)}_$i',
        name: colorName.isEmpty ? d.name : '$colorName ${d.name}',
        slot: d.slot,
        style: d.style,
        color: color,
        accent: accent,
        pattern: d.pattern,
        price: price,
        tags: d.tags,
      ));
    }
  }
  return items;
}

String _slug(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

// ---------- Makeup palettes ----------

const skinTones = <Color>[
  Color(0xFFFCE3D3),
  Color(0xFFF1C9A5),
  Color(0xFFE0A87E),
  Color(0xFFC68B59),
  Color(0xFF9C6644),
  Color(0xFF6F4530),
];

const hairColors = <Color>[
  Color(0xFF1B1212),
  Color(0xFF3E2723),
  Color(0xFF6D4C41),
  Color(0xFFB5651D),
  Color(0xFFE6BE8A),
  Color(0xFF8E24AA),
  Color(0xFFE91E63),
  Color(0xFF1E88E5),
];

const eyeColors = <Color>[
  Color(0xFF3E2723),
  Color(0xFF795548),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF607D8B),
  Color(0xFF8D6E63),
];

const eyeshadowColors = <Color>[
  Color(0xFFD4AF37),
  Color(0xFFAD1457),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFF8D6E63),
  Color(0xFF1A237E),
  Color(0xFFFF8A65),
  Color(0xFF2E7D32),
];

const lipstickColors = <Color>[
  Color(0xFFC62828),
  Color(0xFFAD1457),
  Color(0xFFE57373),
  Color(0xFFD81B60),
  Color(0xFF8D4F3A),
  Color(0xFF6A1B4D),
  Color(0xFFFF7043),
  Color(0xFFF48FB1),
];

const blushColors = <Color>[
  Color(0xFFF48FB1),
  Color(0xFFFF8A65),
  Color(0xFFE57373),
  Color(0xFFCE93D8),
];
