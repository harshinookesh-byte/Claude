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
}
