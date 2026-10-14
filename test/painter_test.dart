import 'dart:ui' as ui;

import 'package:fashion_star/data/catalog.dart';
import 'package:fashion_star/models/fashion_item.dart';
import 'package:fashion_star/models/look.dart';
import 'package:fashion_star/screens/studio_screen.dart';
import 'package:fashion_star/widgets/model_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thumbnails never paint outside their own box', () async {
    // Paint each slot's thumbnail into a 60x60 box in the middle of a
    // 180x180 transparent image; everything outside the box must stay empty.
    for (final slot in Slot.values) {
      final item = itemsFor(slot).first;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.translate(60, 60);
      ModelPainter(Look(items: {slot: item.id}), focus: thumbnailFocus(slot))
          .paint(canvas, const Size(60, 60));
      final img = await rec.endRecording().toImage(180, 180);
      final data = (await img.toByteData())!;
      var outside = 0, inside = 0;
      for (var y = 0; y < 180; y++) {
        for (var x = 0; x < 180; x++) {
          final alpha = data.getUint8((y * 180 + x) * 4 + 3);
          if (alpha == 0) continue;
          final inBox = x >= 60 && x < 120 && y >= 60 && y < 120;
          inBox ? inside++ : outside++;
        }
      }
      expect(outside, 0, reason: '${slot.name} thumbnail overflows');
      expect(inside, greaterThan(0), reason: '${slot.name} thumbnail is empty');
    }
  });

  test('model always wears a bottom and a top', () async {
    Future<Color> pixel(Look look, int x, int y) async {
      final rec = ui.PictureRecorder();
      ModelPainter(look).paint(Canvas(rec), const Size(300, 600));
      final img = await rec.endRecording().toImage(300, 600);
      final d = (await img.toByteData())!;
      final i = (y * 300 + x) * 4;
      return Color.fromARGB(d.getUint8(i + 3), d.getUint8(i), d.getUint8(i + 1),
          d.getUint8(i + 2));
    }

    const skin = Makeup();
    final tee = itemsFor(Slot.top).firstWhere((i) => i.style == 'tee');
    final jeans = itemsFor(Slot.bottom).firstWhere((i) => i.style == 'jeans');
    final looks = {
      'nothing': const Look(),
      'top only': const Look().toggle(tee),
      'bottom only': const Look().toggle(jeans),
    };
    // Hips, thigh, knee and chest/belly.
    const spots = [(150, 320), (138, 400), (138, 480), (150, 230), (150, 280)];
    for (final MapEntry(key: name, value: look) in looks.entries) {
      for (final (x, y) in spots) {
        final c = await pixel(look, x, y);
        expect(c, isNot(skin.skinTone), reason: '$name: bare skin at ($x, $y)');
      }
    }
  });
}
