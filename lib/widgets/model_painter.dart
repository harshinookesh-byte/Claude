import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/fashion_item.dart';
import '../models/look.dart';

/// Draws a stylised fashion model wearing [look].
///
/// Everything is laid out on a virtual 300 x 600 canvas and scaled to fit;
/// [focus] picks the part of that canvas to show (used for item thumbnails).
class ModelPainter extends CustomPainter {
  ModelPainter(this.look, {this.focus = fullBody});

  static const fullBody = Rect.fromLTWH(0, 0, 300, 600);

  /// Plain leggings and tee always worn under the outfit.
  static const baseBottom = FashionItem(
    id: 'base_bottom',
    name: 'Base leggings',
    slot: Slot.bottom,
    style: 'leggings',
    color: Color(0xFFB8B0C4),
  );
  static const baseTop = FashionItem(
    id: 'base_top',
    name: 'Base tee',
    slot: Slot.top,
    style: 'tee',
    color: Color(0xFFF7F4FA),
  );

  final Look look;
  final Rect focus;

  Makeup get _m => look.makeup;
  FashionItem? _item(Slot s) => itemById(look[s]);

  @override
  void paint(Canvas canvas, Size size) {
    final scale =
        math.min(size.width / focus.width, size.height / focus.height);
    canvas.save();
    // Thumbnails zoom into part of the full drawing; without this clip the
    // rest of the model spills over neighbouring widgets.
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      (size.width - focus.width * scale) / 2 - focus.left * scale,
      (size.height - focus.height * scale) / 2 - focus.top * scale,
    );
    canvas.scale(scale);

    final hair = _item(Slot.hair);
    final dress = _item(Slot.dress);
    final bottom = _item(Slot.bottom);
    final top = _item(Slot.top);
    final shoes = _item(Slot.shoes);
    // The model is never shown undressed: a plain tee and leggings are always
    // worn underneath, covering the torso and legs whatever the outfit.
    final garments =
        [baseBottom, baseTop, bottom, top, dress].whereType<FashionItem>();

    if (hair != null) _hairBack(canvas, hair.style);
    for (final g in garments) {
      _garment(canvas, g, _Pass.back);
    }
    _legs(canvas);
    _torsoSkin(canvas);
    if (shoes == null || shoes.style == 'sandals') _feet(canvas);
    if (shoes != null) _shoes(canvas, shoes);
    for (final g in garments) {
      _garment(canvas, g, _Pass.body);
    }
    _arms(canvas);
    for (final g in garments) {
      _garment(canvas, g, _Pass.sleeves);
    }
    _hands(canvas);

    final bangles = _item(Slot.bangles);
    if (bangles != null) _bangles(canvas, bangles);
    final bag = _item(Slot.bag);
    if (bag != null) _bag(canvas, bag);
    final necklace = _item(Slot.necklace);
    if (necklace != null) _necklace(canvas, necklace);

    _head(canvas);
    if (hair != null) _hairFront(canvas, hair.style);

    final earrings = _item(Slot.earrings);
    if (earrings != null) _earrings(canvas, earrings);
    final head = _item(Slot.headpiece);
    if (head != null) _headpiece(canvas, head, hair?.style);
    final bindi = _item(Slot.bindi);
    if (bindi != null) _bindi(canvas, bindi);
    final nose = _item(Slot.noseRing);
    if (nose != null) _noseRing(canvas, nose);
    final glasses = _item(Slot.glasses);
    if (glasses != null) _glasses(canvas, glasses);

    canvas.restore();
  }

  @override
  bool shouldRepaint(ModelPainter oldDelegate) =>
      oldDelegate.look != look || oldDelegate.focus != focus;

  // ------------------------------------------------------------------
  // Geometry helpers
  // ------------------------------------------------------------------

  static Offset _mirror(Offset p) => Offset(300 - p.dx, p.dy);

  /// Closed path from left-side points (top to bottom) mirrored onto the right.
  static Path _sym(List<Offset> left, {bool smooth = true}) {
    final pts = [...left, ...left.reversed.map(_mirror)];
    return smooth ? _smooth(pts) : (Path()..addPolygon(pts, true));
  }

  static Path _smooth(List<Offset> pts) {
    final path = Path();
    Offset mid(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final n = pts.length;
    final start = mid(pts[n - 1], pts[0]);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      final m = mid(p, pts[(i + 1) % n]);
      path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    return path..close();
  }

  static Path _mirrorPath(Path p) => p.transform((Matrix4.identity()
        ..translate(300.0)
        ..scale(-1.0, 1.0))
      .storage);

  /// Left edge of the body silhouette at height [y].
  static double _bodyX(double y) {
    const pts = [
      (151.0, 136.0),
      (167.0, 112.0),
      (198.0, 120.0),
      (215.0, 122.0),
      (262.0, 130.0),
      (300.0, 118.0),
      (322.0, 114.0),
      (360.0, 117.0),
      (420.0, 122.0),
      (480.0, 124.0),
      (600.0, 127.0),
    ];
    if (y <= pts.first.$1) return pts.first.$2;
    for (var i = 1; i < pts.length; i++) {
      if (y <= pts[i].$1) {
        final (y0, x0) = pts[i - 1];
        final (y1, x1) = pts[i];
        return x0 + (x1 - x0) * (y - y0) / (y1 - y0);
      }
    }
    return pts.last.$2;
  }

  static Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // ------------------------------------------------------------------
  // Fabric rendering
  // ------------------------------------------------------------------

  void _fabric(Canvas c, Path p, FashionItem it,
      {Color? color, FabricPattern? pattern, bool outline = true}) {
    final base = color ?? it.color;
    final b = p.getBounds();
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(colors: [
          _shade(base, -0.10),
          _shade(base, 0.07),
          _shade(base, -0.10),
        ]).createShader(b),
    );
    final pat = pattern ?? it.pattern;
    if (pat != FabricPattern.plain) {
      c.save();
      c.clipPath(p);
      _pattern(c, b, pat, it.accent);
      c.restore();
    }
    if (outline) {
      c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _shade(base, -0.28),
      );
    }
  }

  void _pattern(Canvas c, Rect b, FabricPattern pat, Color accent) {
    final paint = Paint()..color = accent.withAlpha(200);
    switch (pat) {
      case FabricPattern.plain:
        break;
      case FabricPattern.dots:
        var row = 0;
        for (var y = b.top; y < b.bottom; y += 11, row++) {
          for (var x = b.left + (row.isOdd ? 5.5 : 0); x < b.right; x += 11) {
            c.drawCircle(Offset(x, y), 1.8, paint);
          }
        }
      case FabricPattern.stripes:
        paint
          ..color = accent.withAlpha(150)
          ..strokeWidth = 3;
        for (var y = b.top; y < b.bottom; y += 11) {
          c.drawLine(Offset(b.left, y), Offset(b.right, y), paint);
        }
      case FabricPattern.floral:
        var row = 0;
        for (var y = b.top + 6; y < b.bottom; y += 22, row++) {
          for (var x = b.left + (row.isOdd ? 11 : 0); x < b.right; x += 22) {
            _flower(c, Offset(x, y), 4, accent.withAlpha(210),
                _shade(accent, -0.25));
          }
        }
      case FabricPattern.zari:
        paint.color = accent.withAlpha(220);
        var row = 0;
        for (var y = b.top; y < b.bottom; y += 13, row++) {
          for (var x = b.left + (row.isOdd ? 6.5 : 0); x < b.right; x += 13) {
            final d = Path()
              ..moveTo(x, y - 2.4)
              ..lineTo(x + 1.8, y)
              ..lineTo(x, y + 2.4)
              ..lineTo(x - 1.8, y)
              ..close();
            c.drawPath(d, paint);
          }
        }
    }
  }

  static void _flower(Canvas c, Offset o, double r, Color petal, Color center) {
    final p = Paint()..color = petal;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.8, r * 0.55, p);
    }
    c.drawCircle(o, r * 0.45, Paint()..color = center);
  }

  /// Accent band along the hem of [garment], [height] tall, ending at [bottom].
  void _hemBorder(Canvas c, Path garment, FashionItem it, double bottom,
      {double height = 18}) {
    c.save();
    c.clipPath(garment);
    final band = Rect.fromLTRB(0, bottom - height, 300, bottom + 20);
    c.drawRect(band, Paint()..color = it.accent);
    final dark = Paint()..color = _shade(it.accent, -0.2);
    for (var x = 0.0; x < 300; x += 9) {
      c.drawCircle(Offset(x, bottom - height / 2), 2.2, dark);
    }
    c.drawLine(
        Offset(0, bottom - height),
        Offset(300, bottom - height),
        Paint()
          ..color = _shade(it.accent, -0.3)
          ..strokeWidth = 1.5);
    c.restore();
  }

  // ------------------------------------------------------------------
  // Body
  // ------------------------------------------------------------------

  Paint get _skin => Paint()..color = _m.skinTone;
  Paint get _skinLine => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = _shade(_m.skinTone, -0.18);

  static final Path _legPath = _smooth(const [
    Offset(114, 318),
    Offset(122, 390),
    Offset(127, 445),
    Offset(130, 500),
    Offset(132, 556),
    Offset(148, 556),
    Offset(146, 500),
    Offset(147, 445),
    Offset(150, 372),
    Offset(150, 336),
  ]);

  static List<Offset> _armPoints({double pad = 0}) => [
        Offset(116, 163 - pad),
        Offset(104 - pad, 171),
        Offset(98 - pad, 200),
        Offset(94 - pad, 255),
        Offset(91 - pad, 322),
        Offset(104 + pad, 324),
        Offset(108 + pad, 258),
        Offset(113 + pad, 212),
        Offset(122 + pad, 194),
      ];

  void _legs(Canvas c) {
    for (final p in [_legPath, _mirrorPath(_legPath)]) {
      c.drawPath(p, _skin);
      c.drawPath(p, _skinLine);
    }
  }

  void _torsoSkin(Canvas c) {
    final torso = _sym(const [
      Offset(140, 140),
      Offset(140, 152),
      Offset(114, 165),
      Offset(120, 198),
      Offset(128, 262),
      Offset(113, 322),
      Offset(150, 340),
    ]);
    c.drawPath(torso, _skin);
    c.drawPath(torso, _skinLine);
    // Collarbones and navel give the bare torso a little form.
    final line = _skinLine..strokeWidth = 1;
    c.drawArc(
        const Rect.fromLTWH(122, 156, 22, 10), math.pi * 1.1, 0.8, false, line);
    c.drawArc(
        const Rect.fromLTWH(156, 156, 22, 10), math.pi * 1.9, 0.8, false, line);
    c.drawOval(const Rect.fromLTWH(148.5, 280, 3, 5), line);
  }

  void _arms(Canvas c) {
    final arm = _smooth(_armPoints());
    for (final p in [arm, _mirrorPath(arm)]) {
      c.drawPath(p, _skin);
      c.drawPath(p, _skinLine);
    }
  }

  void _hands(Canvas c) {
    for (final x in [97.5, 202.5]) {
      final r = Rect.fromCenter(center: Offset(x, 334), width: 15, height: 21);
      c.drawOval(r, _skin);
      c.drawOval(r, _skinLine);
    }
  }

  static final Path _footPath = _smooth(const [
    Offset(131, 548),
    Offset(148, 548),
    Offset(150, 572),
    Offset(144, 586),
    Offset(134, 586),
    Offset(129, 570),
  ]);

  void _feet(Canvas c) {
    for (final p in [_footPath, _mirrorPath(_footPath)]) {
      c.drawPath(p, _skin);
      c.drawPath(p, _skinLine);
    }
  }

  // ------------------------------------------------------------------
  // Garment shapes
  // ------------------------------------------------------------------

  /// Upper-body garment from the shoulders (or [strapless] from the bust)
  /// down to [bottom]. Below [flareFrom] the sides widen by [flare] per px.
  Path _bodice(double bottom,
      {double pad = 2,
      double flare = 0,
      double flareFrom = 290,
      double neckDepth = 10,
      bool vNeck = false,
      bool strapless = false}) {
    final left = <Offset>[];
    final topY = strapless ? 196.0 : 166.0;
    for (var y = topY; y < bottom; y += 8) {
      left.add(Offset(_edge(y, pad, flare, flareFrom), y));
    }
    left.add(Offset(_edge(bottom, pad, flare, flareFrom), bottom));

    final p = Path();
    if (strapless) {
      p.moveTo(150, 204);
      p.quadraticBezierTo(136, 188, left.first.dx, left.first.dy);
    } else {
      p.moveTo(150, 150 + neckDepth + (vNeck ? 24 : 0));
      if (vNeck) {
        p.lineTo(138, 151);
      } else {
        p.quadraticBezierTo(140, 150 + neckDepth, 137, 150);
      }
    }
    for (final o in left) {
      p.lineTo(o.dx, o.dy);
    }
    p.quadraticBezierTo(150, bottom + 5, 300 - left.last.dx, left.last.dy);
    for (final o in left.reversed.skip(1)) {
      p.lineTo(300 - o.dx, o.dy);
    }
    if (strapless) {
      p.quadraticBezierTo(164, 188, 150, 204);
    } else if (vNeck) {
      p.lineTo(162, 151);
    } else {
      p.lineTo(163, 150);
    }
    return p..close();
  }

  static double _edge(double y, double pad, double flare, double flareFrom) {
    var x = _bodyX(y) - pad;
    if (y > flareFrom) x -= (y - flareFrom) * flare;
    return x;
  }

  /// Skirt from the waist ([top]) down to [bottom], widening by [flare].
  Path _skirt(double top, double bottom, double flare, {double pad = 2}) {
    final left = <Offset>[];
    for (var y = top; y < bottom; y += 8) {
      left.add(Offset(_bodyX(y) - pad - (y - top) * flare, y));
    }
    left.add(Offset(_bodyX(bottom) - pad - (bottom - top) * flare, bottom));
    final p = Path()..moveTo(left.first.dx, left.first.dy);
    for (final o in left.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    p.quadraticBezierTo(150, bottom + 8, 300 - left.last.dx, left.last.dy);
    for (final o in left.reversed.skip(1)) {
      p.lineTo(300 - o.dx, o.dy);
    }
    return p..close();
  }

  /// Trousers from the waist to [bottom]; [wide] adds width at the hem.
  Path _pants(double bottom, {double pad = 2, double wide = 0}) {
    double t(double y) => ((y - 320) / (bottom - 320)).clamp(0.0, 1.0);
    final outer = <Offset>[];
    for (var y = 258.0; y < bottom; y += 10) {
      outer.add(Offset(_bodyX(y) - pad - wide * t(y), y));
    }
    final outerBottom = Offset(_bodyX(bottom) - pad - wide * t(bottom), bottom);
    final innerX = 147.5 + pad * 0.3 + wide * 0.35 * t(bottom);
    final p = Path()..moveTo(150, 258);
    for (final o in outer) {
      p.lineTo(o.dx, o.dy);
    }
    p.lineTo(outerBottom.dx, outerBottom.dy);
    p.lineTo(math.min(innerX, 149), bottom);
    p.lineTo(149.5, 344);
    p.lineTo(300 - math.min(innerX, 149), bottom);
    p.lineTo(300 - outerBottom.dx, outerBottom.dy);
    for (final o in outer.reversed) {
      p.lineTo(300 - o.dx, o.dy);
    }
    return p..close();
  }

  void _sleeves(Canvas c, FashionItem it, double end,
      {double pad = 2.5, Color? color, bool puff = false}) {
    if (end > 0) _sleeveTubes(c, it, end, pad, color);
    if (puff) {
      for (final o in const [Offset(108, 176), Offset(192, 176)]) {
        final r = Rect.fromCenter(center: o, width: 30, height: 32);
        final p = Path()..addOval(r);
        _fabric(c, p, it, color: color, pattern: FabricPattern.plain);
      }
    }
  }

  void _sleeveTubes(
      Canvas c, FashionItem it, double end, double pad, Color? color) {
    final arm = _smooth(_armPoints(pad: pad));
    for (final p in [arm, _mirrorPath(arm)]) {
      c.save();
      c.clipRect(Rect.fromLTRB(0, 0, 300, end));
      _fabric(c, p, it, color: color);
      c.restore();
    }
    final cuff = Paint()
      ..color = _shade(color ?? it.color, -0.3)
      ..strokeWidth = 1.4;
    final lx = 99.0 - (end - 200) * 0.04;
    c.drawLine(Offset(lx - pad - 3, end), Offset(lx + 15 + pad, end), cuff);
    c.drawLine(
        Offset(300 - lx + pad + 3, end), Offset(285 - lx - pad, end), cuff);
  }

  void _straps(Canvas c, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(128, 162), const Offset(130, 200), p);
    c.drawLine(const Offset(172, 162), const Offset(170, 200), p);
  }

  void _garment(Canvas c, FashionItem it, _Pass pass) {
    switch (it.style) {
      // ---------------- dresses ----------------
      case 'saree':
        _saree(c, it, pass);
      case 'lehenga':
        if (pass == _Pass.back) _dupattaTails(c, it.accent.withAlpha(170));
        if (pass == _Pass.body) {
          final skirt = _skirt(256, 580, 0.33);
          _fabric(c, skirt, it);
          _kalis(c, it, 256, 580, 0.33);
          _hemBorder(c, skirt, it, 588, height: 24);
          final blouse = _bodice(238, pad: 1);
          _fabric(c, blouse, it, color: _shade(it.color, -0.06));
          _hemBorder(c, blouse, it, 241, height: 5);
        }
        if (pass == _Pass.sleeves) {
          _sleeves(c, it, 215, color: _shade(it.color, -0.06));
          _dupattaFront(c, it.accent.withAlpha(150));
        }
      case 'anarkali':
        if (pass == _Pass.body) {
          _fabric(c, _pants(552, pad: 0.5), it,
              color: it.accent, pattern: FabricPattern.plain);
          final skirt = _skirt(246, 515, 0.42);
          _fabric(c, skirt, it);
          _kalis(c, it, 246, 515, 0.42);
          _hemBorder(c, skirt, it, 522, height: 14);
          _fabric(c, _bodice(250, pad: 1), it);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 318, pad: 1.5);
      case 'salwar':
        if (pass == _Pass.back) _dupattaTails(c, it.accent.withAlpha(190));
        if (pass == _Pass.body) {
          final salwar = _pants(552, pad: 3, wide: 10);
          _fabric(c, salwar, it,
              color: it.accent, pattern: FabricPattern.plain);
          final kameez = _bodice(445, pad: 3, flare: 0.1, flareFrom: 300);
          _fabric(c, kameez, it);
          _hemBorder(c, kameez, it, 448, height: 8);
        }
        if (pass == _Pass.sleeves) {
          _sleeves(c, it, 288);
          _dupattaFront(c, it.accent.withAlpha(200));
        }
      case 'gown':
        if (pass == _Pass.body) {
          final skirt = _skirt(262, 588, 0.22);
          _fabric(c, skirt, it);
          _sparkles(c, skirt, it.accent, 28);
          final bodice = _bodice(268, strapless: true, pad: 0.5);
          _fabric(c, bodice, it);
          _sparkles(c, bodice, it.accent, 8);
        }
      case 'ballgown':
        if (pass == _Pass.body) {
          final skirt = _skirt(256, 590, 0.48);
          _fabric(c, skirt, it);
          _scallops(c, it, 590, 0.48, 256);
          _fabric(c, _bodice(262, pad: 1), it, pattern: FabricPattern.plain);
          _bow(c, const Offset(150, 258), it.accent);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 0, puff: true);
      case 'minidress':
        if (pass == _Pass.body) {
          final skirt = _skirt(262, 385, 0.32);
          _fabric(c, skirt, it);
          _fabric(c, _bodice(268, strapless: true, pad: 0.5), it);
          _straps(c, it.color);
          _sparkles(c, skirt, it.accent, 10);
        }
      case 'sundress':
        if (pass == _Pass.body) {
          final skirt = _skirt(258, 455, 0.3);
          _fabric(c, skirt, it);
          _fabric(c, _bodice(262, strapless: true, pad: 0.5), it);
          _straps(c, it.accent);
          _bow(c, const Offset(150, 258), it.accent);
        }
      case 'jumpsuit':
        if (pass == _Pass.body) {
          final pants = _pants(550, pad: 3, wide: 6);
          _fabric(c, pants, it, pattern: FabricPattern.plain);
          _sideStripes(c, it.accent);
          _fabric(c, _bodice(270, pad: 2, vNeck: true), it,
              pattern: FabricPattern.plain);
          c.drawLine(
              const Offset(150, 184),
              const Offset(150, 270),
              Paint()
                ..color = it.accent
                ..strokeWidth = 2);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 212);

      // ---------------- tops ----------------
      case 'tee':
        if (pass == _Pass.body) _fabric(c, _bodice(288, pad: 3), it);
        if (pass == _Pass.sleeves) _sleeves(c, it, 210, pad: 3.5);
      case 'crop':
        if (pass == _Pass.body) _fabric(c, _bodice(242, pad: 2), it);
        if (pass == _Pass.sleeves) _sleeves(c, it, 204);
      case 'choli':
        if (pass == _Pass.body) {
          final b = _bodice(238, pad: 1, neckDepth: 16);
          _fabric(c, b, it);
          _hemBorder(c, b, it, 241, height: 5);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 214);
      case 'kurti':
        if (pass == _Pass.body) {
          final k =
              _bodice(412, pad: 3, flare: 0.12, flareFrom: 300, vNeck: true);
          _fabric(c, k, it);
          _hemBorder(c, k, it, 414, height: 7);
          final trim = Paint()
            ..color = it.accent
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
          c.drawPath(
              Path()
                ..moveTo(139, 152)
                ..lineTo(150, 184)
                ..lineTo(161, 152),
              trim);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 288);
      case 'blazer':
        if (pass == _Pass.body) {
          _fabric(c, _bodice(262, pad: 1, neckDepth: 6), it, color: it.accent);
          _fabric(c, _bodice(338, pad: 5, vNeck: true), it);
          final lapel = Paint()..color = _shade(it.color, -0.12);
          c.drawPath(
              Path()
                ..moveTo(138, 151)
                ..lineTo(150, 230)
                ..lineTo(132, 200)
                ..close(),
              lapel);
          c.drawPath(
              Path()
                ..moveTo(162, 151)
                ..lineTo(150, 230)
                ..lineTo(168, 200)
                ..close(),
              lapel);
          for (final y in [252.0, 280.0]) {
            c.drawCircle(Offset(150, y), 2.5, Paint()..color = it.accent);
          }
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 322, pad: 3.5);
      case 'hoodie':
        if (pass == _Pass.back) {
          c.drawOval(const Rect.fromLTWH(118, 136, 64, 34),
              Paint()..color = _shade(it.color, -0.15));
        }
        if (pass == _Pass.body) {
          _fabric(c, _bodice(322, pad: 7), it);
          final pocket = Path()
            ..moveTo(128, 300)
            ..lineTo(172, 300)
            ..lineTo(180, 322)
            ..lineTo(120, 322)
            ..close();
          _fabric(c, pocket, it, color: _shade(it.color, -0.05));
          final str = Paint()
            ..color = it.accent
            ..strokeWidth = 2;
          c.drawLine(const Offset(144, 158), const Offset(143, 200), str);
          c.drawLine(const Offset(156, 158), const Offset(157, 200), str);
        }
        if (pass == _Pass.sleeves) _sleeves(c, it, 324, pad: 5);
      case 'tank':
        if (pass == _Pass.body) {
          final t = _bodice(282, strapless: true, pad: 1.5);
          _fabric(c, t, it);
          _hemBorder(c, t, it, 282, height: 3);
          _straps(c, it.accent);
        }

      // ---------------- bottoms ----------------
      case 'jeans':
        if (pass == _Pass.body) {
          final p = _pants(548, pad: 1.5);
          _fabric(c, p, it);
          _seams(c, it);
        }
      case 'shorts':
        if (pass == _Pass.body) {
          _fabric(c, _pants(372, pad: 3, wide: 6), it);
          _seams(c, it);
        }
      case 'leggings':
        if (pass == _Pass.body) _fabric(c, _pants(550, pad: 0.5), it);
      case 'palazzo':
        if (pass == _Pass.body) {
          final p = _pants(558, pad: 4, wide: 24);
          _fabric(c, p, it);
          _hemBorder(c, p, it, 561, height: 6);
        }
      case 'miniskirt':
        if (pass == _Pass.body) {
          final s = _skirt(258, 372, 0.3);
          _fabric(c, s, it);
          _pleats(c, s, 258, 372, 0.3, it);
        }
      case 'pencil':
        if (pass == _Pass.body) {
          final s = _skirt(258, 452, -0.02, pad: 3);
          _fabric(c, s, it);
          c.drawLine(
              const Offset(158, 420),
              const Offset(158, 452),
              Paint()
                ..color = _shade(it.color, -0.3)
                ..strokeWidth = 1.2);
        }
      case 'lehengaskirt':
        if (pass == _Pass.body) {
          final s = _skirt(256, 580, 0.33);
          _fabric(c, s, it);
          _kalis(c, it, 256, 580, 0.33);
          _hemBorder(c, s, it, 588, height: 24);
        }
    }
  }

  void _saree(Canvas c, FashionItem it, _Pass pass) {
    // The pallu falls over the left shoulder and down the back.
    final pallu = it.color;
    if (pass == _Pass.back) {
      final tail = _smooth(const [
        Offset(104, 168),
        Offset(124, 164),
        Offset(122, 300),
        Offset(112, 430),
        Offset(80, 424),
        Offset(90, 300),
      ]);
      _fabric(c, tail, it, color: _shade(pallu, -0.05));
      _hemBorder(c, tail, it, 432, height: 14);
    }
    if (pass == _Pass.body) {
      final skirt = _skirt(258, 582, 0.1);
      _fabric(c, skirt, it);
      // Front pleats.
      final pleat = Paint()
        ..color = _shade(it.color, -0.22)
        ..strokeWidth = 1.2;
      for (var i = -3; i <= 3; i++) {
        c.drawLine(
            Offset(150 + i * 3.0, 330), Offset(150 + i * 9.0, 584), pleat);
      }
      _hemBorder(c, skirt, it, 590, height: 20);
      final blouse = _bodice(234, pad: 1, neckDepth: 14);
      _fabric(c, blouse, it, color: _shade(it.color, -0.12));
      // Diagonal drape across the body.
      final drape = Path()
        ..moveTo(106, 168)
        ..lineTo(138, 151)
        ..quadraticBezierTo(170, 210, 188, 296)
        ..lineTo(178, 330)
        ..quadraticBezierTo(140, 260, 118, 214)
        ..close();
      _fabric(c, drape, it, color: pallu);
      c.save();
      c.clipPath(drape);
      final border = Paint()
        ..color = it.accent
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke;
      c.drawPath(
          Path()
            ..moveTo(138, 151)
            ..quadraticBezierTo(170, 210, 188, 296),
          border);
      c.restore();
    }
    if (pass == _Pass.sleeves) {
      _sleeves(c, it, 212, color: _shade(it.color, -0.12));
    }
  }

  void _dupattaTails(Canvas c, Color color) {
    final p = Paint()..color = color;
    for (final tail in [
      _smooth(const [
        Offset(108, 168),
        Offset(124, 166),
        Offset(118, 300),
        Offset(110, 440),
        Offset(86, 436),
        Offset(94, 300),
      ]),
    ]) {
      c.drawPath(tail, p);
      c.drawPath(_mirrorPath(tail), p);
    }
  }

  void _dupattaFront(Canvas c, Color color) {
    final p = Path()
      ..moveTo(108, 168)
      ..quadraticBezierTo(150, 250, 192, 168)
      ..lineTo(186, 162)
      ..quadraticBezierTo(150, 228, 114, 162)
      ..close();
    c.drawPath(p, Paint()..color = color);
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _shade(color.withAlpha(255), -0.2));
  }

  /// Radiating panel lines on flared Indian skirts.
  void _kalis(
      Canvas c, FashionItem it, double top, double bottom, double flare) {
    final p = Paint()
      ..color = _shade(it.color, -0.2)
      ..strokeWidth = 1;
    final topHalf = 150 - (_bodyX(top) - 2);
    final botHalf = 150 - (_bodyX(bottom) - 2 - (bottom - top) * flare);
    for (var i = -3; i <= 3; i++) {
      if (i == 0) continue;
      c.drawLine(Offset(150 + topHalf * i / 4, top + 2),
          Offset(150 + botHalf * i / 4, bottom), p);
    }
  }

  void _pleats(Canvas c, Path skirt, double top, double bottom, double flare,
      FashionItem it) {
    c.save();
    c.clipPath(skirt);
    final p = Paint()
      ..color = _shade(it.color, -0.25)
      ..strokeWidth = 1.2;
    for (var i = -5; i <= 5; i++) {
      c.drawLine(
          Offset(150 + i * 4.0, top), Offset(150 + i * 10.0, bottom + 6), p);
    }
    c.restore();
  }

  void _scallops(
      Canvas c, FashionItem it, double bottom, double flare, double top) {
    final half = 150 - (_bodyX(bottom) - 2 - (bottom - top) * flare);
    final p = Paint()..color = it.accent.withAlpha(200);
    final n = 9;
    final w = half * 2 / n;
    for (var i = 0; i < n; i++) {
      final cx = 150 - half + w * (i + 0.5);
      c.drawArc(
          Rect.fromCenter(
              center: Offset(cx, bottom - 10), width: w, height: 26),
          0,
          math.pi,
          true,
          p);
    }
  }

  void _sparkles(Canvas c, Path area, Color color, int count) {
    final b = area.getBounds();
    final rnd = math.Random(count * 7 + b.top.toInt());
    final p = Paint()..color = color.withAlpha(220);
    c.save();
    c.clipPath(area);
    for (var i = 0; i < count; i++) {
      final o = Offset(b.left + rnd.nextDouble() * b.width,
          b.top + rnd.nextDouble() * b.height);
      _star(c, o, 2.2 + rnd.nextDouble() * 1.5, p);
    }
    c.restore();
  }

  static void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy - r * 1.6)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 1.6, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 1.6)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 1.6, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 1.6);
    c.drawPath(path, p);
  }

  void _bow(Canvas c, Offset o, Color color) {
    final p = Paint()..color = color;
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx - 14, o.dy - 8)
          ..lineTo(o.dx - 14, o.dy + 8)
          ..close()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + 14, o.dy - 8)
          ..lineTo(o.dx + 14, o.dy + 8)
          ..close(),
        p);
    c.drawCircle(o, 4, Paint()..color = _shade(color, -0.15));
  }

  void _seams(Canvas c, FashionItem it) {
    final p = Paint()
      ..color = it.accent.withAlpha(180)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawLine(const Offset(150, 262), const Offset(150, 336), p);
    c.drawArc(const Rect.fromLTWH(124, 262, 20, 24), 0, math.pi / 2, false, p);
    c.drawArc(const Rect.fromLTWH(156, 262, 20, 24), math.pi / 2, math.pi / 2,
        false, p);
  }

  void _sideStripes(Canvas c, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3;
    c.drawLine(const Offset(113, 300), const Offset(118, 548), p);
    c.drawLine(const Offset(187, 300), const Offset(182, 548), p);
  }

  // ------------------------------------------------------------------
  // Shoes
  // ------------------------------------------------------------------

  void _shoes(Canvas c, FashionItem it) {
    for (final mirror in [false, true]) {
      c.save();
      if (mirror) {
        c.translate(300, 0);
        c.scale(-1, 1);
      }
      _shoe(c, it);
      c.restore();
    }
  }

  void _shoe(Canvas c, FashionItem it) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _shade(it.color, -0.3);
    switch (it.style) {
      case 'heels':
        final shoe = _smooth(const [
          Offset(131, 557),
          Offset(148, 556),
          Offset(150, 574),
          Offset(141, 592),
          Offset(130, 576),
        ]);
        _fabric(c, shoe, it, pattern: FabricPattern.plain);
        c.drawLine(
            const Offset(131, 550),
            const Offset(148, 550),
            Paint()
              ..color = it.color
              ..strokeWidth = 2.5);
        c.drawCircle(const Offset(145, 550), 1.8, Paint()..color = it.accent);
      case 'sneakers':
        final shoe = _smooth(const [
          Offset(127, 546),
          Offset(150, 546),
          Offset(153, 574),
          Offset(146, 590),
          Offset(128, 590),
          Offset(124, 572),
        ]);
        _fabric(c, shoe, it, pattern: FabricPattern.plain);
        c.drawRect(const Rect.fromLTRB(125, 582, 152, 590),
            Paint()..color = Colors.white);
        c.drawRect(const Rect.fromLTRB(125, 582, 152, 590), outline);
        final lace = Paint()
          ..color = it.accent
          ..strokeWidth = 1.6;
        for (var y = 556.0; y < 576; y += 6) {
          c.drawLine(Offset(132, y), Offset(146, y), lace);
        }
      case 'jutti':
        final shoe = Path()
          ..moveTo(129, 560)
          ..quadraticBezierTo(140, 552, 150, 560)
          ..quadraticBezierTo(150, 584, 140, 596)
          ..quadraticBezierTo(136, 586, 129, 578)
          ..close();
        _fabric(c, shoe, it, pattern: FabricPattern.zari);
      case 'sandals':
        final strap = Paint()
          ..color = it.color
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(130, 566), const Offset(149, 566), strap);
        c.drawLine(const Offset(132, 552), const Offset(147, 552), strap);
        c.drawCircle(const Offset(140, 566), 2.5, Paint()..color = it.accent);
        c.drawPath(
            _footPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = _shade(it.color, -0.1));
      case 'boots':
        final shaft = _pants(552, pad: 3);
        c.save();
        c.clipRect(const Rect.fromLTRB(0, 455, 150, 600));
        _fabric(c, shaft, it, pattern: FabricPattern.plain);
        c.restore();
        final shoe = _smooth(const [
          Offset(127, 548),
          Offset(150, 548),
          Offset(152, 576),
          Offset(144, 592),
          Offset(130, 592),
          Offset(125, 572),
        ]);
        _fabric(c, shoe, it, pattern: FabricPattern.plain);
        c.drawLine(
            const Offset(124, 458),
            const Offset(150, 458),
            Paint()
              ..color = it.accent
              ..strokeWidth = 3);
      case 'glassslipper':
        final shoe = _smooth(const [
          Offset(130, 556),
          Offset(149, 556),
          Offset(151, 574),
          Offset(141, 590),
          Offset(129, 574),
        ]);
        c.drawPath(_footPath, _skin);
        c.drawPath(shoe, Paint()..color = it.color.withAlpha(150));
        c.drawPath(
            shoe,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.white);
        _star(c, const Offset(140, 562), 2.5, Paint()..color = Colors.white);
    }
  }

  // ------------------------------------------------------------------
  // Head & makeup
  // ------------------------------------------------------------------

  static final Path _facePath = _sym(const [
    Offset(150, 46),
    Offset(126, 52),
    Offset(114, 76),
    Offset(114, 104),
    Offset(122, 124),
    Offset(136, 136),
    Offset(150, 141),
  ]);

  void _head(Canvas c) {
    // Neck.
    final neck = Path()
      ..moveTo(139, 120)
      ..lineTo(139, 156)
      ..quadraticBezierTo(150, 162, 161, 156)
      ..lineTo(161, 120)
      ..close();
    c.drawPath(neck, _skin);
    c.drawPath(neck, Paint()..color = _shade(_m.skinTone, -0.06));

    for (final x in [113.0, 187.0]) {
      final r = Rect.fromCenter(center: Offset(x, 98), width: 11, height: 20);
      c.drawOval(r, _skin);
      c.drawOval(r, _skinLine);
    }
    c.drawPath(
      _facePath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.8,
          colors: [_shade(_m.skinTone, 0.04), _m.skinTone],
        ).createShader(const Rect.fromLTWH(114, 46, 72, 95)),
    );
    c.drawPath(_facePath, _skinLine);

    if (_m.blush != null) {
      for (final o in const [Offset(128, 114), Offset(172, 114)]) {
        c.drawCircle(
          o,
          12,
          Paint()
            ..shader = RadialGradient(colors: [
              _m.blush!.withAlpha(140),
              _m.blush!.withAlpha(0),
            ]).createShader(Rect.fromCircle(center: o, radius: 12)),
        );
      }
    }

    _eye(c, const Offset(136, 96), -1);
    _eye(c, const Offset(164, 96), 1);

    final brow = Paint()
      ..color = _shade(_m.hairColor, -0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    c.drawPath(
        Path()
          ..moveTo(146, 81)
          ..quadraticBezierTo(136, 75, 125, 81),
        brow);
    c.drawPath(
        Path()
          ..moveTo(154, 81)
          ..quadraticBezierTo(164, 75, 175, 81),
        brow);

    // Nose.
    c.drawPath(
        Path()
          ..moveTo(150, 101)
          ..quadraticBezierTo(146, 111, 149, 113)
          ..quadraticBezierTo(152, 114, 154, 112),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = _shade(_m.skinTone, -0.2));

    // Lips.
    final lipColor = _m.lipstick ??
        Color.lerp(_shade(_m.skinTone, -0.12), const Color(0xFFD87A7A), 0.4)!;
    final upper = Path()
      ..moveTo(139, 124)
      ..quadraticBezierTo(145, 117, 150, 120.5)
      ..quadraticBezierTo(155, 117, 161, 124)
      ..quadraticBezierTo(150, 126, 139, 124)
      ..close();
    final lower = Path()
      ..moveTo(139, 124)
      ..quadraticBezierTo(150, 134, 161, 124)
      ..quadraticBezierTo(150, 126.5, 139, 124)
      ..close();
    c.drawPath(upper, Paint()..color = _shade(lipColor, -0.05));
    c.drawPath(lower, Paint()..color = lipColor);
    c.drawOval(
        const Rect.fromLTWH(147, 127, 6, 2),
        Paint()
          ..color = Colors.white.withAlpha(_m.lipstick != null ? 110 : 50));
  }

  /// [side] is -1 for the eye on the viewer's left, 1 for the right.
  void _eye(Canvas c, Offset o, int side) {
    if (_m.eyeshadow != null) {
      c.drawOval(
        Rect.fromCenter(center: o + const Offset(0, -5), width: 26, height: 15),
        Paint()
          ..color = _m.eyeshadow!.withAlpha(160)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
    final almond = Path()
      ..moveTo(o.dx - 10, o.dy)
      ..quadraticBezierTo(o.dx, o.dy - 10, o.dx + 10, o.dy)
      ..quadraticBezierTo(o.dx, o.dy + 7, o.dx - 10, o.dy)
      ..close();
    c.drawPath(almond, Paint()..color = Colors.white);
    c.save();
    c.clipPath(almond);
    c.drawCircle(o + const Offset(0, -1), 5.2, Paint()..color = _m.eyeColor);
    c.drawCircle(o + const Offset(0, -1), 2.5, Paint()..color = Colors.black);
    c.drawCircle(
        o + const Offset(1.6, -2.8), 1.4, Paint()..color = Colors.white);
    c.restore();

    final lid = Paint()
      ..color = const Color(0xFF2B1B17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _m.eyeliner ? 2.6 : 1.4
      ..strokeCap = StrokeCap.round;
    final top = Path()
      ..moveTo(o.dx - 10, o.dy)
      ..quadraticBezierTo(o.dx, o.dy - 10, o.dx + 10, o.dy);
    c.drawPath(top, lid);
    final outer = o + Offset(10.0 * side, 0);
    if (_m.eyeliner) {
      c.drawLine(outer, outer + Offset(5.0 * side, -4), lid);
    }
    if (_m.lashes) {
      final lash = Paint()
        ..color = const Color(0xFF1B1212)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final t = 0.35 + i * 0.2;
        final x = o.dx + side * (t * 10);
        final y = o.dy - 5 * (1 - t * t) - 1;
        c.drawLine(Offset(x, y), Offset(x + side * 2.5, y - 3.5), lash);
      }
    }
  }

  // ------------------------------------------------------------------
  // Hair
  // ------------------------------------------------------------------

  Paint _hairPaint(Rect bounds) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _shade(_m.hairColor, 0.08),
        _m.hairColor,
        _shade(_m.hairColor, -0.06)
      ],
    ).createShader(bounds);

  void _drawHair(Canvas c, Path p) {
    c.drawPath(p, _hairPaint(p.getBounds()));
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _shade(_m.hairColor, -0.12));
  }

  void _strands(Canvas c, Path area, double top, double bottom) {
    c.save();
    c.clipPath(area);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _shade(_m.hairColor, 0.12).withAlpha(120);
    for (var x = 96.0; x < 206; x += 7) {
      c.drawPath(
          Path()
            ..moveTo(x, top)
            ..quadraticBezierTo(x + 6, (top + bottom) / 2, x - 2, bottom),
          p);
    }
    c.restore();
  }

  void _hairBack(Canvas c, String style) {
    switch (style) {
      case 'long':
        final p = _sym(const [
          Offset(150, 38),
          Offset(112, 54),
          Offset(103, 110),
          Offset(104, 200),
          Offset(110, 266),
          Offset(150, 252),
        ]);
        _drawHair(c, p);
        _strands(c, p, 60, 266);
      case 'wavy':
        final left = <Offset>[const Offset(150, 36), const Offset(108, 52)];
        for (var y = 90.0; y <= 290; y += 20) {
          left.add(Offset(98 - 6 * math.sin(y / 16) - (y - 90) * 0.03, y));
        }
        left.add(const Offset(150, 270));
        final p = _sym(left);
        _drawHair(c, p);
        _strands(c, p, 60, 296);
      case 'bun':
        final bun = Path()
          ..addOval(Rect.fromCircle(center: const Offset(150, 40), radius: 24));
        _drawHair(c, bun);
        final swirl = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _shade(_m.hairColor, 0.12);
        c.drawArc(Rect.fromCircle(center: const Offset(150, 40), radius: 14),
            0.3, 4, false, swirl);
      case 'ponytail':
        final tail = Path()
          ..moveTo(166, 46)
          ..quadraticBezierTo(214, 70, 206, 160)
          ..quadraticBezierTo(200, 220, 190, 250)
          ..quadraticBezierTo(182, 200, 186, 140)
          ..quadraticBezierTo(188, 90, 160, 60)
          ..close();
        _drawHair(c, tail);
        _strands(c, tail, 50, 250);
      case 'bob':
        final pts = <Offset>[];
        for (var i = 0; i <= 16; i++) {
          final a = math.pi * 0.95 + i * (math.pi * 1.1 / 16);
          final r = 50 + (i.isEven ? 5 : 0);
          pts.add(Offset(150 + math.cos(a) * r, 90 + math.sin(a) * r));
        }
        pts.addAll(const [
          Offset(200, 120),
          Offset(196, 150),
          Offset(180, 156),
          Offset(150, 146),
          Offset(120, 156),
          Offset(104, 150),
          Offset(100, 120),
        ]);
        _drawHair(c, _smooth(pts));
      case 'updo':
        final p = Path()
          ..addOval(const Rect.fromLTWH(108, 24, 84, 60))
          ..addOval(Rect.fromCircle(center: const Offset(150, 22), radius: 17));
        _drawHair(c, p);
      case 'braid':
        // The braid is drawn in front, over the shoulder.
        break;
    }
  }

  void _hairFront(Canvas c, String style) {
    // Hair cap over the top of the head with a parting / fringe.
    final cap = switch (style) {
      'bob' => _smooth(const [
          Offset(110, 104),
          Offset(108, 66),
          Offset(128, 44),
          Offset(150, 40),
          Offset(172, 44),
          Offset(192, 66),
          Offset(190, 104),
          Offset(184, 80),
          Offset(174, 72),
          Offset(150, 76),
          Offset(126, 72),
          Offset(116, 80),
        ]),
      'bun' || 'updo' || 'ponytail' => _smooth(const [
          Offset(112, 102),
          Offset(110, 64),
          Offset(130, 44),
          Offset(150, 41),
          Offset(170, 44),
          Offset(190, 64),
          Offset(188, 102),
          Offset(182, 76),
          Offset(166, 62),
          Offset(150, 66),
          Offset(134, 62),
          Offset(118, 76),
        ]),
      _ => _smooth(const [
          Offset(112, 108),
          Offset(108, 66),
          Offset(128, 43),
          Offset(150, 39),
          Offset(172, 43),
          Offset(192, 66),
          Offset(188, 108),
          Offset(182, 84),
          Offset(172, 66),
          Offset(158, 62),
          Offset(140, 70),
          Offset(124, 84),
        ]),
    };
    _drawHair(c, cap);

    switch (style) {
      case 'long':
      case 'wavy':
        final lock = _smooth([
          const Offset(110, 84),
          const Offset(124, 90),
          const Offset(127, 170),
          Offset(style == 'wavy' ? 120 : 124, 236),
          const Offset(108, 230),
          const Offset(103, 160),
        ]);
        _drawHair(c, lock);
        _drawHair(c, _mirrorPath(lock));
      case 'braid':
        final p = Paint();
        for (var i = 0; i < 10; i++) {
          final y = 120.0 + i * 18;
          final x = 176.0 + i * 1.4 + (i.isEven ? -2 : 2);
          final r = Rect.fromCenter(
              center: Offset(x, y), width: 22 - i * 0.8, height: 22);
          final path = Path()..addOval(r);
          p.shader = _hairPaint(r).shader;
          c.drawPath(path, p);
          c.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = _shade(_m.hairColor, -0.12));
        }
        c.drawCircle(const Offset(190, 304), 4,
            Paint()..color = const Color(0xFFFFC94A));
      case 'ponytail':
        c.drawOval(const Rect.fromLTWH(160, 44, 14, 10),
            Paint()..color = const Color(0xFFE91E63));
    }
  }

  // ------------------------------------------------------------------
  // Jewellery & accessories
  // ------------------------------------------------------------------

  void _necklace(Canvas c, FashionItem it) {
    Offset curve(double t, double depth) {
      // Quadratic bezier around the neckline.
      const a = Offset(137, 152), b = Offset(163, 152);
      final ctrl = Offset(150, 152 + depth);
      final u = 1 - t;
      return a * (u * u) + ctrl * (2 * u * t) + b * (t * t);
    }

    switch (it.style) {
      case 'pearl':
        for (var i = 0; i <= 14; i++) {
          final o = curve(i / 14, 34);
          c.drawCircle(o, 2.6, Paint()..color = it.color);
          c.drawCircle(
              o,
              2.6,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.6
                ..color = const Color(0xFFBDBDBD));
        }
      case 'kundan':
        final band = Path()
          ..moveTo(curve(0, 18).dx, curve(0, 18).dy)
          ..quadraticBezierTo(150, 170, 163, 152);
        c.drawPath(
            band,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = it.color);
        for (var i = 1; i < 8; i++) {
          final o = curve(i / 8, 18);
          c.drawCircle(o, 2.6, Paint()..color = it.accent);
          final drop = o + const Offset(0, 8);
          c.drawLine(
              o,
              drop,
              Paint()
                ..color = it.color
                ..strokeWidth = 1);
          c.drawCircle(drop, 1.8, Paint()..color = Colors.white);
        }
        // Long haar beneath the choker.
        final haar = Path()
          ..moveTo(136, 154)
          ..quadraticBezierTo(150, 238, 164, 154);
        c.drawPath(
            haar,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = it.color);
        c.drawCircle(const Offset(150, 196), 5, Paint()..color = it.accent);
        c.drawCircle(
            const Offset(150, 196),
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = it.color);
      case 'pendant':
        final chain = Path()
          ..moveTo(137, 152)
          ..quadraticBezierTo(150, 212, 163, 152);
        c.drawPath(
            chain,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = it.color);
        final h = Path()
          ..moveTo(150, 194)
          ..cubicTo(144, 186, 141, 192, 150, 200)
          ..cubicTo(159, 192, 156, 186, 150, 194);
        c.drawPath(h, Paint()..color = it.accent);
    }
  }

  void _earrings(Canvas c, FashionItem it) {
    for (final x in [113.0, 187.0]) {
      final lobe = Offset(x, 106);
      switch (it.style) {
        case 'jhumka':
          c.drawCircle(lobe, 2.8, Paint()..color = it.accent);
          final bell = Path()
            ..moveTo(x - 6, 122)
            ..quadraticBezierTo(x - 6, 110, x, 110)
            ..quadraticBezierTo(x + 6, 110, x + 6, 122)
            ..close();
          c.drawLine(
              lobe,
              Offset(x, 110),
              Paint()
                ..color = it.color
                ..strokeWidth = 1.2);
          c.drawPath(bell, Paint()..color = it.color);
          for (var i = -2; i <= 2; i++) {
            c.drawCircle(
                Offset(x + i * 2.6, 124.5), 1.3, Paint()..color = it.accent);
          }
        case 'hoops':
          c.drawCircle(
              Offset(x, 115),
              8.5,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8
                ..color = it.color);
        case 'studs':
          c.drawCircle(lobe, 2.8, Paint()..color = it.color);
          _star(c, lobe, 2.2, Paint()..color = Colors.white);
      }
    }
  }

  void _headpiece(Canvas c, FashionItem it, String? hair) {
    switch (it.style) {
      case 'tikka':
        c.drawLine(
            const Offset(150, 42),
            const Offset(150, 62),
            Paint()
              ..color = it.color
              ..strokeWidth = 1.5);
        final drop = Path()
          ..moveTo(150, 60)
          ..quadraticBezierTo(157, 68, 150, 75)
          ..quadraticBezierTo(143, 68, 150, 60);
        c.drawPath(drop, Paint()..color = it.color);
        c.drawCircle(const Offset(150, 68), 3, Paint()..color = it.accent);
      case 'tiara':
        final crown = Path()..moveTo(124, 54);
        const peaks = [(130, 40), (140, 46), (150, 30), (160, 46), (170, 40)];
        for (final (x, y) in peaks) {
          crown.lineTo(x.toDouble(), y.toDouble());
          crown.lineTo(x + 5.0, 50);
        }
        crown
          ..lineTo(176, 54)
          ..quadraticBezierTo(150, 46, 124, 54)
          ..close();
        c.drawPath(crown, Paint()..color = it.color);
        c.drawPath(
            crown,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xFF9E9E9E));
        for (final (x, y) in peaks) {
          c.drawCircle(
              Offset(x.toDouble(), y + 4.0), 2.2, Paint()..color = it.accent);
        }
      case 'flowers':
        final center =
            hair == 'bun' ? const Offset(150, 40) : const Offset(150, 64);
        final rx = hair == 'bun' ? 26.0 : 44.0;
        final ry = hair == 'bun' ? 26.0 : 28.0;
        for (var i = 0; i <= 8; i++) {
          final a = math.pi * (1.05 + i * 0.9 / 8);
          final o = center + Offset(math.cos(a) * rx, math.sin(a) * ry);
          _flower(c, o, 5, it.color, it.accent);
        }
      case 'headband':
        c.drawPath(
            Path()
              ..moveTo(112, 82)
              ..quadraticBezierTo(150, 22, 188, 82),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round
              ..color = it.color);
    }
  }

  void _bindi(Canvas c, FashionItem it) {
    if (it.style == 'jewel') {
      final drop = Path()
        ..moveTo(150, 79)
        ..quadraticBezierTo(154.5, 85, 150, 88)
        ..quadraticBezierTo(145.5, 85, 150, 79);
      c.drawPath(drop, Paint()..color = it.color);
      for (final dx in [-4.0, 0.0, 4.0]) {
        c.drawCircle(Offset(150 + dx, 76 - (dx == 0 ? 1 : 0)), 0.9,
            Paint()..color = it.accent);
      }
    } else {
      c.drawCircle(const Offset(150, 84), 2.8, Paint()..color = it.color);
    }
  }

  void _noseRing(Canvas c, FashionItem it) {
    if (it.style == 'nath') {
      c.drawCircle(
          const Offset(141, 117),
          8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = it.color);
      c.drawCircle(const Offset(141, 125), 2, Paint()..color = it.accent);
      final chain = Path()
        ..moveTo(134, 114)
        ..quadraticBezierTo(116, 112, 114, 86);
      c.drawPath(
          chain,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = it.color);
    } else {
      c.drawCircle(const Offset(145, 111), 1.6, Paint()..color = it.color);
      _star(c, const Offset(145, 111), 1.2, Paint()..color = Colors.white);
    }
  }

  void _bangles(Canvas c, FashionItem it) {
    for (final x in [97.5, 202.5]) {
      final count = it.style == 'bracelet' ? 1 : 4;
      for (var i = 0; i < count; i++) {
        c.drawOval(
          Rect.fromCenter(
              center: Offset(x, 314 + i * 3.6), width: 19, height: 6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = i.isEven ? it.color : it.accent,
        );
      }
      if (it.style == 'bracelet') {
        c.drawCircle(Offset(x, 320), 2, Paint()..color = it.accent);
      }
    }
  }

  void _bag(Canvas c, FashionItem it) {
    switch (it.style) {
      case 'clutch':
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(207, 344), width: 36, height: 20),
            const Radius.circular(4));
        c.drawRRect(r, Paint()..color = it.color);
        _sparkles(c, Path()..addRRect(r), it.accent, 6);
        c.drawPath(
            Path()
              ..moveTo(189, 336)
              ..lineTo(207, 346)
              ..lineTo(225, 336),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = _shade(it.color, -0.3));
      case 'potli':
        c.drawLine(
            const Offset(203, 336),
            const Offset(204, 352),
            Paint()
              ..color = it.accent
              ..strokeWidth = 1.2);
        final body = Path()
          ..moveTo(196, 356)
          ..quadraticBezierTo(184, 384, 204, 386)
          ..quadraticBezierTo(224, 384, 212, 356)
          ..close();
        _fabric(c, body, it, pattern: FabricPattern.zari);
        c.drawLine(
            const Offset(195, 357),
            const Offset(213, 357),
            Paint()
              ..color = it.accent
              ..strokeWidth = 3);
      case 'tote':
        c.drawArc(
            const Rect.fromLTWH(193, 320, 22, 40),
            math.pi,
            math.pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = it.accent);
        final body = Path()
          ..moveTo(186, 340)
          ..lineTo(222, 340)
          ..lineTo(226, 384)
          ..lineTo(182, 384)
          ..close();
        _fabric(c, body, it);
    }
  }

  void _glasses(Canvas c, FashionItem it) {
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = it.style == 'specs' ? it.color : it.accent;
    for (final side in [-1.0, 1.0]) {
      final o = Offset(150 + 14 * side, 96);
      final lens = it.style == 'specs'
          ? (Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: o, width: 22, height: 15),
                const Radius.circular(4))))
          : (Path()
            ..moveTo(o.dx - 11 * side, o.dy - 6)
            ..quadraticBezierTo(o.dx, o.dy - 9, o.dx + 13 * side, o.dy - 8)
            ..quadraticBezierTo(o.dx + 10 * side, o.dy + 9, o.dx, o.dy + 8)
            ..quadraticBezierTo(
                o.dx - 11 * side, o.dy + 6, o.dx - 11 * side, o.dy - 6)
            ..close());
      if (it.style != 'specs') {
        c.drawPath(lens, Paint()..color = it.color.withAlpha(225));
      } else {
        c.drawPath(lens, Paint()..color = Colors.white.withAlpha(50));
      }
      c.drawPath(lens, frame);
    }
    c.drawLine(const Offset(147, 93), const Offset(153, 93), frame);
  }
}

enum _Pass { back, body, sleeves }
