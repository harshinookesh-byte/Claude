import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../data/catalog.dart';
import '../data/challenges.dart';
import '../models/fashion_item.dart';
import '../models/look.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../theme/tokens.dart';
import '../widgets/model_painter.dart';
import 'runway_screen.dart';

/// Makeup salon + wardrobe. With a [challenge] it leads to the runway,
/// otherwise it is a free-style studio that saves to the gallery.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key, this.challenge});

  final Challenge? challenge;

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

enum _MakeupTab {
  skin('Skin'),
  hairColor('Hair color'),
  eyes('Eyes'),
  shadow('Eyeshadow'),
  liner('Liner'),
  lips('Lips'),
  blush('Blush');

  const _MakeupTab(this.label);
  final String label;
}

const _dressSlots = [
  Slot.hair,
  Slot.dress,
  Slot.top,
  Slot.bottom,
  Slot.shoes,
  Slot.necklace,
  Slot.earrings,
  Slot.headpiece,
  Slot.bindi,
  Slot.noseRing,
  Slot.bangles,
  Slot.bag,
  Slot.glasses,
];

class _StudioScreenState extends State<StudioScreen> {
  late Look _look;
  final _history = <Look>[];
  // Challenges start in the makeup salon, like the original game's flow.
  late bool _makeupMode = widget.challenge != null;
  _MakeupTab _makeupTab = _MakeupTab.skin;
  Slot _slot = Slot.hair;

  @override
  void initState() {
    super.initState();
    _look = GameScope.read(context).current;
  }

  void _apply(Look next) {
    setState(() {
      _history.add(_look);
      if (_history.length > 50) _history.removeAt(0);
      _look = next;
    });
    GameScope.read(context).setLook(next);
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() => _look = _history.removeLast());
    GameScope.read(context).setLook(_look);
  }

  Future<void> _tapItem(FashionItem item) async {
    final game = GameScope.read(context);
    if (!game.owns(item)) {
      final choice = await showDialog<_Unlock>(
        context: context,
        builder: (ctx) => _UnlockDialog(item: item, coins: game.coins),
      );
      if (choice == null || !mounted) return;
      if (choice == _Unlock.ad) {
        final earned = await AdScope.read(context).showRewarded();
        if (!mounted) return;
        if (!earned) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Watch the whole video to unlock the item.')));
          return;
        }
        game.unlockFree(item);
      } else if (!game.buy(item)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough coins yet. Win a show to earn more.')));
        return;
      }
    }
    _apply(_look.toggle(item));
  }

  void _randomize() {
    final game = GameScope.read(context);
    final rnd = math.Random();
    FashionItem? pick(Slot s) {
      final owned = itemsFor(s).where(game.owns).toList();
      return owned.isEmpty ? null : owned[rnd.nextInt(owned.length)];
    }

    var look = Look(makeup: _look.makeup);
    final slots = [
      Slot.hair,
      Slot.shoes,
      if (rnd.nextBool()) Slot.dress else ...[Slot.top, Slot.bottom],
      ...(_dressSlots.where((s) => s.isAccessory).toList()..shuffle(rnd))
          .take(3),
    ];
    for (final s in slots) {
      final it = pick(s);
      if (it != null) look = look.toggle(it);
    }
    _apply(look);
  }

  void _finish() {
    final challenge = widget.challenge;
    if (challenge == null) {
      GameScope.read(context).saveToGallery(_look);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved to your looks')));
      return;
    }
    if (!_look.hasOutfit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Your model needs an outfit first: a dress, or a top and a bottom.')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RunwayScreen(challenge: challenge, look: _look),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopBar(title: challenge?.title ?? 'Studio'),
            if (challenge != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(kMargin, 0, kMargin, 4),
                child: Text(challenge.brief, style: Txt.small()),
              ),
            Expanded(
              child: Stack(
                children: [
                  // The model holds her place while the outfit changes.
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: ModelView(look: _look, crossfade: true)),
                    ),
                  ),
                  Positioned(
                    right: kMargin,
                    top: 8,
                    child: Column(
                      children: [
                        ToolButton(
                            icon: Icons.undo,
                            tooltip: 'Undo',
                            onTap: _history.isEmpty ? null : _undo),
                        const SizedBox(height: 8),
                        ToolButton(
                            icon: Icons.shuffle,
                            tooltip: 'Surprise me',
                            onTap: _randomize),
                        const SizedBox(height: 8),
                        ToolButton(
                            icon: Icons.restart_alt,
                            tooltip: 'Reset',
                            onTap: () => _apply(GameState.defaultLook)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _panel(),
          ],
        ),
      ),
    );
  }

  Widget _panel() {
    return ColoredBox(
      color: Palette.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kMargin, 12, kMargin, 4),
              child: TextTabs<bool>(
                values: const [true, false],
                selected: _makeupMode,
                label: (v) => v ? 'Makeup' : 'Dress up',
                onSelect: (v) => setState(() => _makeupMode = v),
              ),
            ),
            SizedBox(
              key: const Key('categories'),
              height: 44,
              child: _makeupMode
                  ? TextTabs<_MakeupTab>(
                      scrollable: true,
                      values: _MakeupTab.values,
                      selected: _makeupTab,
                      label: (t) => t.label,
                      onSelect: (t) => setState(() => _makeupTab = t),
                    )
                  : TextTabs<Slot>(
                      scrollable: true,
                      values: _dressSlots,
                      selected: _slot,
                      label: (s) => s.label,
                      marked: (s) => _look[s] != null,
                      onSelect: (s) => setState(() => _slot = s),
                    ),
            ),
            SizedBox(
              key: const Key('tray'),
              height: 148,
              child: _makeupMode ? _makeupTray() : _itemTray(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kMargin, 4, kMargin, 12),
              child: PrimaryButton(
                label:
                    widget.challenge == null ? 'Save look' : 'Walk the runway',
                onPressed: _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTray() {
    final game = GameScope.of(context);
    final items = itemsFor(_slot);
    return ListView(
      key: PageStorageKey(_slot),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kMargin - 4, vertical: 8),
      children: [
        _NoneTile(
          selected: _look[_slot] == null,
          onTap: () => _apply(_look.clear(_slot)),
        ),
        for (final it in items)
          _ItemTile(
            item: it,
            makeup: _look.makeup,
            owned: game.owns(it),
            selected: _look[_slot] == it.id,
            onTap: () => _tapItem(it),
          ),
      ],
    );
  }

  Widget _makeupTray() {
    final m = _look.makeup;
    void set(Makeup next) => _apply(_look.withMakeup(next));

    Widget swatches(
        List<Color> colors, Color? selected, ValueChanged<Color?> pick,
        {bool allowNone = true}) {
      return ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: kMargin - 6, vertical: 30),
        children: [
          if (allowNone)
            _Swatch(
                color: null,
                selected: selected == null,
                onTap: () => pick(null)),
          for (final c in colors)
            _Swatch(color: c, selected: selected == c, onTap: () => pick(c)),
        ],
      );
    }

    return switch (_makeupTab) {
      _MakeupTab.skin => swatches(
          skinTones, m.skinTone, (c) => set(m.copyWith(skinTone: c)),
          allowNone: false),
      _MakeupTab.hairColor => swatches(
          hairColors, m.hairColor, (c) => set(m.copyWith(hairColor: c)),
          allowNone: false),
      _MakeupTab.eyes => swatches(
          eyeColors, m.eyeColor, (c) => set(m.copyWith(eyeColor: c)),
          allowNone: false),
      _MakeupTab.shadow => swatches(eyeshadowColors, m.eyeshadow,
          (c) => set(m.copyWith(eyeshadow: () => c))),
      _MakeupTab.lips => swatches(lipstickColors, m.lipstick,
          (c) => set(m.copyWith(lipstick: () => c))),
      _MakeupTab.blush =>
        swatches(blushColors, m.blush, (c) => set(m.copyWith(blush: () => c))),
      _MakeupTab.liner => Padding(
          padding: const EdgeInsets.fromLTRB(kMargin, 28, kMargin, 28),
          child: Row(
            children: [
              _Toggle(
                label: 'Winged liner',
                on: m.eyeliner,
                onTap: () => set(m.copyWith(eyeliner: !m.eyeliner)),
              ),
              const SizedBox(width: 12),
              _Toggle(
                label: 'Lashes',
                on: m.lashes,
                onTap: () => set(m.copyWith(lashes: !m.lashes)),
              ),
            ],
          ),
        ),
    };
  }
}

/// Region of the model canvas to show in each slot's thumbnails.
Rect thumbnailFocus(Slot slot) => switch (slot) {
      Slot.hair => const Rect.fromLTRB(86, 14, 214, 270),
      Slot.dress => const Rect.fromLTRB(10, 140, 290, 600),
      Slot.top => const Rect.fromLTRB(80, 140, 220, 420),
      Slot.bottom => const Rect.fromLTRB(20, 250, 280, 600),
      Slot.shoes => const Rect.fromLTRB(110, 440, 190, 600),
      Slot.necklace => const Rect.fromLTRB(118, 135, 182, 215),
      Slot.earrings => const Rect.fromLTRB(96, 80, 134, 140),
      Slot.headpiece => const Rect.fromLTRB(104, 18, 196, 100),
      Slot.bindi => const Rect.fromLTRB(128, 64, 172, 100),
      Slot.noseRing => const Rect.fromLTRB(110, 80, 170, 135),
      Slot.bangles => const Rect.fromLTRB(76, 290, 120, 345),
      Slot.bag => const Rect.fromLTRB(172, 300, 236, 400),
      Slot.glasses => const Rect.fromLTRB(116, 72, 184, 118),
    };

/// The slot's zoomed-in region of the model, letterboxed so nothing outside
/// that region shows.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.look, required this.slot});

  final Look look;
  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final focus = thumbnailFocus(slot);
    return Center(
      child: AspectRatio(
        aspectRatio: focus.width / focus.height,
        child: CustomPaint(painter: ModelPainter(look, focus: focus)),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.makeup,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final FashionItem item;
  final Makeup makeup;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = Look(makeup: makeup, items: {item.slot: item.id});
    final fg = selected ? Palette.accentInk : Palette.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: owned ? item.name : '${item.name}, ${item.price} coins',
        child: Pressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 100,
            color: selected ? Palette.accent : Palette.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _Thumbnail(look: preview, slot: item.slot),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Txt.small(fg).copyWith(height: 1.2),
                      ),
                      if (!owned)
                        Text(
                          '${item.price} coins',
                          style: Txt.small(
                                  selected ? Palette.accentInk : Palette.muted)
                              .copyWith(height: 1.2, fontFeatures: Txt.tabular),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoneTile extends StatelessWidget {
  const _NoneTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'None',
        child: Pressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 72,
            alignment: Alignment.center,
            color: selected ? Palette.accent : Palette.raised,
            child: Text('None',
                style: Txt.small(selected ? Palette.accentInk : Palette.ink)),
          ),
        ),
      ),
    );
  }
}

/// A makeup colour. Round, because it is the colour itself; the chosen one
/// sits inside an accent ring.
class _Swatch extends StatelessWidget {
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        selected: selected,
        label: color == null ? 'None' : 'Colour',
        child: Pressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Palette.accent : Colors.transparent,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? Palette.raised,
              ),
              child: color == null
                  ? Center(child: Text('None', style: Txt.small(Palette.ink)))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          color: on ? Palette.accent : Palette.raised,
          child: Text(label,
              style: Txt.body(on ? Palette.accentInk : Palette.ink)),
        ),
      ),
    );
  }
}

enum _Unlock { coins, ad }

class _UnlockDialog extends StatelessWidget {
  const _UnlockDialog({required this.item, required this.coins});

  final FashionItem item;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final affordable = coins >= item.price;
    final adReady = AdScope.of(context).rewardedReady;
    return Dialog(
      insetPadding: const EdgeInsets.all(kMargin),
      child: Padding(
        padding: const EdgeInsets.all(kMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name, style: Txt.lead()),
            const SizedBox(height: 4),
            Text(
              affordable
                  ? 'Unlock it for ${item.price} coins. You have '
                      '${formatCoins(coins)}.'
                  : 'It costs ${item.price} coins and you have '
                      '${formatCoins(coins)}. Win a show to earn more.',
              style: Txt.body(),
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              color: Palette.raised,
              padding: const EdgeInsets.all(8),
              child: _Thumbnail(
                  look: Look(items: {item.slot: item.id}), slot: item.slot),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Unlock for ${item.price} coins',
              onPressed: affordable
                  ? () => Navigator.pop(context, _Unlock.coins)
                  : null,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 24,
              children: [
                if (adReady)
                  TextLink('Watch an ad to unlock',
                      onTap: () => Navigator.pop(context, _Unlock.ad)),
                TextLink('Not now', onTap: () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
