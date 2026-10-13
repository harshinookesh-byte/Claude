import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../models/fashion_item.dart';
import '../models/look.dart';

/// Player progress: coins, XP, unlocked items, saved looks and the look
/// currently being styled. Persisted with shared_preferences.
class GameState extends ChangeNotifier {
  GameState(this._prefs) {
    _load();
  }

  static const _key = 'fashion_star_save_v1';
  static const xpPerLevel = 100;
  static const dailyBonus = 150;

  final SharedPreferences? _prefs;

  int coins = 500;
  int xp = 0;
  int wins = 0;
  int shows = 0;
  final Set<String> _owned = {};
  final List<SavedLook> gallery = [];
  DateTime? _lastDaily;
  Look current = defaultLook;

  static final Look defaultLook = () {
    var look = const Look();
    for (final id in [
      'hair_long-sleek_0',
      'top_basic-tee_1',
      'bottom_skinny-jeans_0',
      'shoes_sneakers_0',
    ]) {
      final it = itemById(id);
      if (it != null) look = look.toggle(it);
    }
    return look;
  }();

  int get level => 1 + xp ~/ xpPerLevel;
  double get levelProgress => (xp % xpPerLevel) / xpPerLevel;

  bool owns(FashionItem item) => item.isFree || _owned.contains(item.id);

  bool get dailyAvailable {
    final last = _lastDaily;
    if (last == null) return true;
    final now = DateTime.now();
    return DateUtils.dateOnly(now).isAfter(DateUtils.dateOnly(last));
  }

  // ---------------- actions ----------------

  bool buy(FashionItem item) {
    if (owns(item) || coins < item.price) return false;
    coins -= item.price;
    _owned.add(item.id);
    _changed();
    return true;
  }

  void setLook(Look look) {
    current = look;
    _changed(persist: false);
  }

  void claimDaily() {
    if (!dailyAvailable) return;
    coins += dailyBonus;
    _lastDaily = DateTime.now();
    _changed();
  }

  /// Records a finished fashion show and returns the coins earned.
  int recordShow({required bool won, required int reward}) {
    shows++;
    final earned = won ? reward : reward ~/ 4;
    coins += earned;
    xp += won ? 40 : 15;
    if (won) wins++;
    _changed();
    return earned;
  }

  void saveToGallery(Look look, {String? title, int? score}) {
    gallery.insert(
      0,
      SavedLook(
        look: look,
        title: title ?? 'Look #${gallery.length + 1}',
        createdAt: DateTime.now(),
        score: score,
      ),
    );
    _changed();
  }

  void deleteFromGallery(SavedLook saved) {
    gallery.remove(saved);
    _changed();
  }

  // ---------------- persistence ----------------

  void _changed({bool persist = true}) {
    notifyListeners();
    if (persist) _save();
  }

  void _load() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      coins = j['coins'] as int? ?? coins;
      xp = j['xp'] as int? ?? 0;
      wins = j['wins'] as int? ?? 0;
      shows = j['shows'] as int? ?? 0;
      _owned.addAll((j['owned'] as List? ?? const []).cast<String>());
      final last = j['daily'] as int?;
      _lastDaily =
          last == null ? null : DateTime.fromMillisecondsSinceEpoch(last);
      gallery.addAll((j['gallery'] as List? ?? const [])
          .map((e) => SavedLook.fromJson((e as Map).cast<String, dynamic>())));
      final cur = j['current'] as Map?;
      if (cur != null) current = Look.fromJson(cur.cast<String, dynamic>());
    } on Object catch (e) {
      debugPrint('Ignoring corrupt save: $e');
    }
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'coins': coins,
        'xp': xp,
        'wins': wins,
        'shows': shows,
        'owned': _owned.toList(),
        'daily': _lastDaily?.millisecondsSinceEpoch,
        'gallery': gallery.map((g) => g.toJson()).toList(),
        'current': current.toJson(),
      }),
    );
  }
}

/// Makes [GameState] available to the widget tree.
class GameScope extends InheritedNotifier<GameState> {
  const GameScope({super.key, required GameState state, required super.child})
      : super(notifier: state);

  static GameState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;

  static GameState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GameScope>()!.notifier!;
}
