import 'package:fashion_star/ads/ad_service.dart';
import 'package:fashion_star/main.dart';
import 'package:fashion_star/state/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates a phone with a status bar and Android's 3-button navigation
/// bar, and checks nothing tappable sits underneath either of them.
const _dpr = 2.75;
const _top = 24.0, _bottom = 48.0;

class _BannerAds extends NoAdService {
  @override
  Widget banner() => const SizedBox(height: 50, child: Placeholder());
}

Future<Size> _setUpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = _dpr;
  const insets = FakeViewPadding(top: _top * _dpr, bottom: _bottom * _dpr);
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  addTearDown(tester.view.reset);
  return tester.view.physicalSize / _dpr;
}

void _expectClear(WidgetTester tester, Finder f, Size screen, String what) {
  final r = tester.getRect(f.first);
  expect(r.bottom, lessThanOrEqualTo(screen.height - _bottom),
      reason: '$what is under the navigation bar ($r)');
  expect(r.top, greaterThanOrEqualTo(_top),
      reason: '$what is under the status bar ($r)');
}

void main() {
  for (final (name, ads) in [
    ('no banner loaded', () => NoAdService()),
    ('banner loaded', () => _BannerAds()),
  ]) {
    group(name, () {
      testWidgets('home, show list, gallery and studio clear system bars',
          (tester) async {
        final screen = await _setUpPhone(tester);
        final game = GameState(null)..saveToGallery(GameState.defaultLook);
        for (var i = 0; i < 7; i++) {
          game.saveToGallery(GameState.defaultLook);
        }
        await tester.pumpWidget(FashionStarApp(state: game, ads: ads()));

        _expectClear(tester, find.text('Free Coins'), screen, 'Home tiles');
        _expectClear(tester, find.text('Fashion Star'), screen, 'Home title');
        if (find.byType(Placeholder).evaluate().isNotEmpty) {
          _expectClear(tester, find.byType(Placeholder), screen, 'Banner');
        }

        await tester.tap(find.text('Gallery'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(GridView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        _expectClear(tester, find.text('Look #1'), screen, 'Last gallery card');
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Studio'));
        await tester.pumpAndSettle();
        _expectClear(tester, find.text('SAVE LOOK'), screen, 'Studio button');
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.text('FASHION SHOW'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        _expectClear(tester, find.text('Princess Ball'), screen, 'Last show');
      });

      testWidgets('runway result buttons clear the navigation bar',
          (tester) async {
        final screen = await _setUpPhone(tester);
        await tester
            .pumpWidget(FashionStarApp(state: GameState(null), ads: ads()));
        await tester.tap(find.text('FASHION SHOW'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Street Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('WALK THE RUNWAY'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Tap to skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tap to skip'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        _expectClear(tester, find.text('CONTINUE'), screen, 'Continue');
      });
    });
  }
}
