import 'package:fashion_star/data/catalog.dart';
import 'package:fashion_star/main.dart';
import 'package:fashion_star/models/look.dart';
import 'package:fashion_star/state/game_state.dart';
import 'package:fashion_star/widgets/model_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every catalog item paints without errors', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(children: [
        for (final it in catalog)
          SizedBox(
            width: 30,
            height: 60,
            child: CustomPaint(
              painter: ModelPainter(const Look(
                makeup: Makeup(
                  lipstick: Color(0xFFC62828),
                  eyeshadow: Color(0xFF6A1B9A),
                  blush: Color(0xFFF48FB1),
                  eyeliner: true,
                  lashes: true,
                ),
              ).toggle(it)),
            ),
          ),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('play a fashion show from the home screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final game = GameState(null);
    await tester.pumpWidget(FashionStarApp(state: game));
    expect(find.text('Fashion Star'), findsOneWidget);

    await tester.tap(find.text('FASHION SHOW'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Street Style'));
    await tester.pumpAndSettle();

    // Challenges open in the makeup salon.
    await tester.scrollUntilVisible(find.text('Lips'), 100,
        scrollable: _list('categories'));
    await tester.ensureVisible(find.text('Lips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lips'));
    await tester.pump();
    await tester.tap(find.text('Dress Up'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Shoes'), 100,
        scrollable: _list('categories'));
    await tester.ensureVisible(find.text('Shoes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shoes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WALK THE RUNWAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Skip both runway walks, then wait for the judges.
    await tester.tap(find.text('Tap to skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tap to skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('CONTINUE'), findsOneWidget);
    expect(game.shows, 1);
    await tester.tap(find.text('Save Look'));
    await tester.pump();
    expect(game.gallery, hasLength(1));

    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Fashion Star'), findsOneWidget);
  });

  testWidgets('studio buys locked items and saves to gallery', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final game = GameState(null);
    await tester.pumpWidget(FashionStarApp(state: game));
    await tester.tap(find.text('Studio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dresses'));
    await tester.pumpAndSettle();
    // Second colourway of the chiffon saree is locked.
    final saree = catalog.firstWhere((i) => i.name == 'Mint Chiffon Saree');
    await tester.scrollUntilVisible(find.text(saree.name), 100,
        scrollable: _list('tray'));
    await tester.ensureVisible(find.text(saree.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(saree.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(game.owns(saree), isTrue);
    expect(game.current[saree.slot], saree.id);

    await tester.tap(find.text('SAVE LOOK'));
    await tester.pump();
    expect(game.gallery, hasLength(1));
  });
}

Finder _list(String key) => find.descendant(
    of: find.byKey(Key(key)), matching: find.byType(Scrollable));
