import 'dart:convert';
import 'dart:math' as math;

import 'package:fashion_star/data/catalog.dart';
import 'package:fashion_star/data/challenges.dart';
import 'package:fashion_star/logic/scoring.dart';
import 'package:fashion_star/models/fashion_item.dart';
import 'package:fashion_star/models/look.dart';
import 'package:fashion_star/state/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FashionItem first(Slot slot, String style) =>
    itemsFor(slot).firstWhere((i) => i.style == style);

void main() {
  test('catalog ids are unique and every slot has items', () {
    final ids = catalog.map((i) => i.id).toSet();
    expect(ids.length, catalog.length);
    for (final slot in Slot.values) {
      expect(itemsFor(slot), isNotEmpty, reason: slot.name);
    }
  });

  test('default look items exist', () {
    final look = GameState.defaultLook;
    expect(look.items.length, 4);
    expect(look.hasOutfit, isTrue);
  });

  test('dress replaces top and bottom, and vice versa', () {
    var look = GameState.defaultLook;
    look = look.toggle(first(Slot.dress, 'saree'));
    expect(look[Slot.top], isNull);
    expect(look[Slot.bottom], isNull);
    expect(look.hasOutfit, isTrue);
    look = look.toggle(first(Slot.top, 'choli'));
    expect(look[Slot.dress], isNull);
    expect(look.hasOutfit, isFalse);
  });

  test('toggling a worn item removes it', () {
    final saree = first(Slot.dress, 'saree');
    final look = const Look().toggle(saree).toggle(saree);
    expect(look[Slot.dress], isNull);
  });

  test('look survives a JSON round trip', () {
    final look = const Look(
      makeup: Makeup(lipstick: Color(0xFFC62828), eyeliner: true),
    ).toggle(first(Slot.dress, 'lehenga')).toggle(first(Slot.bindi, 'dot'));
    final back = Look.fromJson(
        jsonDecode(jsonEncode(look.toJson())) as Map<String, dynamic>);
    expect(back.items, look.items);
    expect(back.makeup.lipstick, look.makeup.lipstick);
    expect(back.makeup.eyeshadow, isNull);
    expect(back.makeup.eyeliner, isTrue);
    expect(back.makeup.skinTone, look.makeup.skinTone);
  });

  test('an on-theme bridal look beats a casual one at the wedding', () {
    final wedding = challenges.firstWhere((c) => c.id == 'wedding');
    var bride = const Look(
      makeup: Makeup(
        lipstick: Color(0xFFC62828),
        eyeshadow: Color(0xFFD4AF37),
        blush: Color(0xFFF48FB1),
        eyeliner: true,
        lashes: true,
      ),
    );
    for (final it in [
      first(Slot.dress, 'lehenga'),
      first(Slot.hair, 'bun'),
      first(Slot.shoes, 'jutti'),
      first(Slot.necklace, 'kundan'),
      first(Slot.earrings, 'jhumka'),
      first(Slot.headpiece, 'tikka'),
      first(Slot.noseRing, 'nath'),
    ]) {
      bride = bride.toggle(it);
    }
    final brideScore = scoreLook(bride, wedding);
    final casualScore = scoreLook(GameState.defaultLook, wedding);
    expect(brideScore.total, greaterThan(90));
    expect(casualScore.total, lessThan(40));
    expect(brideScore.judgeMarks, everyElement(inInclusiveRange(1, 10)));
  });

  test('a look with no outfit scores poorly on style', () {
    final s = scoreLook(const Look(), challenges.first);
    expect(s.total, lessThan(10));
  });

  test('rival looks always have an outfit', () {
    final rnd = math.Random(1);
    for (final c in challenges) {
      for (var i = 0; i < 20; i++) {
        expect(rivalLook(c, rnd).hasOutfit, isTrue);
      }
    }
  });

  test('game state persists progress', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final game = GameState(prefs);
    final paid = catalog.firstWhere((i) => i.price > 0 && i.price <= 500);
    expect(game.owns(paid), isFalse);
    expect(game.buy(paid), isTrue);
    game.recordShow(won: true, reward: 100);
    game.claimDaily();
    game.saveToGallery(game.current, title: 'Test', score: 77);

    final reloaded = GameState(prefs);
    expect(reloaded.owns(paid), isTrue);
    expect(reloaded.coins, 500 - paid.price + 100 + GameState.dailyBonus);
    expect(reloaded.wins, 1);
    expect(reloaded.dailyAvailable, isFalse);
    expect(reloaded.gallery.single.score, 77);
  });

  test('cannot buy without enough coins', () async {
    final game = GameState(null)..coins = 10;
    final paid = catalog.firstWhere((i) => i.price > 10);
    expect(game.buy(paid), isFalse);
    expect(game.coins, 10);
  });
}
