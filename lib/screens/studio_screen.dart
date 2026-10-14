import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/challenges.dart';
import '../models/fashion_item.dart';
import '../models/look.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
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
  skin('Skin', Icons.face),
  hairColor('Hair Color', Icons.palette),
  eyes('Eyes', Icons.remove_red_eye),
  shadow('Eyeshadow', Icons.gradient),
  liner('Liner', Icons.edit),
  lips('Lips', Icons.favorite),
  blush('Blush', Icons.blur_on);

  const _MakeupTab(this.label, this.icon);
  final String label;
  final IconData icon;
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
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _UnlockDialog(item: item, coins: game.coins),
      );
      if (ok != true || !mounted) return;
      if (!game.buy(item)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins - win a show!')));
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Look saved to your gallery!')));
      return;
    }
    if (!_look.hasOutfit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Your model needs an outfit: a dress, or a top and bottom!')));
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
      body: StudioBackground(
        colors: challenge == null
            ? null
            : [challenge.gradient.first.withAlpha(90), const Color(0xFFFFF0F7)],
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(challenge),
              Expanded(
                child: Stack(
                  children: [
                    Center(child: ModelView(look: _look)),
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Column(
                        children: [
                          _RoundAction(
                              icon: Icons.undo,
                              tooltip: 'Undo',
                              onTap: _history.isEmpty ? null : _undo),
                          _RoundAction(
                              icon: Icons.casino,
                              tooltip: 'Surprise me',
                              onTap: _randomize),
                          _RoundAction(
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
      ),
    );
  }

  Widget _topBar(Challenge? challenge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: challenge == null
                ? const Text('Style Studio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(challenge.brief,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
          ),
          const CoinChip(),
        ],
      ),
    );
  }

  Widget _panel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: true,
                      label: Text('Makeup'),
                      icon: Icon(Icons.brush)),
                  ButtonSegment(
                      value: false,
                      label: Text('Dress Up'),
                      icon: Icon(Icons.checkroom)),
                ],
                selected: {_makeupMode},
                onSelectionChanged: (s) =>
                    setState(() => _makeupMode = s.first),
              ),
            ),
            SizedBox(
              key: const Key('categories'),
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _makeupMode
                    ? [
                        for (final t in _MakeupTab.values)
                          _CategoryChip(
                            label: t.label,
                            icon: t.icon,
                            selected: t == _makeupTab,
                            onTap: () => setState(() => _makeupTab = t),
                          ),
                      ]
                    : [
                        for (final s in _dressSlots)
                          _CategoryChip(
                            label: s.label,
                            icon: s.icon,
                            selected: s == _slot,
                            dot: _look[s] != null,
                            onTap: () => setState(() => _slot = s),
                          ),
                      ],
              ),
            ),
            SizedBox(
              key: const Key('tray'),
              height: 118,
              child: _makeupMode ? _makeupTray() : _itemTray(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GradientButton(
                label:
                    widget.challenge == null ? 'SAVE LOOK' : 'WALK THE RUNWAY',
                icon: widget.challenge == null
                    ? Icons.bookmark_add
                    : Icons.auto_awesome,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
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
      _MakeupTab.liner => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          children: [
            FilterChip(
              label: const Text('Winged eyeliner'),
              selected: m.eyeliner,
              onSelected: (v) => set(m.copyWith(eyeliner: v)),
            ),
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('Lashes'),
              selected: m.lashes,
              onSelected: (v) => set(m.copyWith(lashes: v)),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 84,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFE4F2) : const Color(0xFFF7F2FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFFF4FA3) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _Thumbnail(look: preview, slot: item.slot),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (!owned)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text('${item.price}',
                            style: const TextStyle(
                                color: Color(0xFFFFE082),
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
            ],
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFFF4FA3) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: const Icon(Icons.block, color: Colors.black38),
        ),
      ),
    );
  }
}

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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? const Color(0xFFF2F2F2),
            border: Border.all(
              color: selected ? const Color(0xFFFF4FA3) : Colors.white,
              width: selected ? 4 : 2,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 4)
            ],
          ),
          child: color == null
              ? const Icon(Icons.block, color: Colors.black38)
              : null,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.dot = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: ChoiceChip(
        avatar: Badge(
          isLabelVisible: dot,
          smallSize: 7,
          backgroundColor: const Color(0xFFFF4FA3),
          child: Icon(icon, size: 16),
        ),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: tooltip,
        child: Material(
          shape: const CircleBorder(),
          color: Colors.white,
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon,
                  color:
                      onTap == null ? Colors.black26 : const Color(0xFF9C4DCC)),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockDialog extends StatelessWidget {
  const _UnlockDialog({required this.item, required this.coins});

  final FashionItem item;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final affordable = coins >= item.price;
    return AlertDialog(
      title: Text('Unlock ${item.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            child: _Thumbnail(
                look: Look(items: {item.slot: item.id}), slot: item.slot),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFC107)),
              const SizedBox(width: 4),
              Text('${item.price}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          if (!affordable)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Win fashion shows to earn more coins!',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now')),
        FilledButton(
          onPressed: affordable ? () => Navigator.pop(context, true) : null,
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
