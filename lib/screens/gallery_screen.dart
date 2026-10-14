import 'dart:async';

import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../models/look.dart';
import '../state/game_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Saved looks shown the way a lookbook shows a collection: one frame stays
/// put and its contents change. Tap the frame to move on; pick any look from
/// the list underneath.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const _hold = Duration(milliseconds: 2400);

  int _index = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer =
        reduceMotion(context) ? null : Timer.periodic(_hold, (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    final n = GameScope.read(context).gallery.length;
    if (n > 1) setState(() => _index = (_index + 1) % n);
  }

  void _select(int i) {
    // A deliberate choice holds the frame for a full beat before moving on.
    _timer?.cancel();
    setState(() => _index = i);
    if (!reduceMotion(context)) {
      _timer = Timer.periodic(_hold, (_) => _next());
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final looks = game.gallery;
    if (_index >= looks.length) _index = 0;
    return Scaffold(
      bottomNavigationBar: const BannerSlot(),
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Your looks', showCoins: false),
            Expanded(
              child: looks.isEmpty
                  ? const _Empty()
                  : _Lookbook(
                      looks: looks,
                      index: _index,
                      onAdvance: () => _select((_index + 1) % looks.length),
                      onSelect: _select,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kMargin, 24, kMargin, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Entrance(
            index: 0,
            child: Text('Nothing saved yet', style: Txt.head()),
          ),
          const SizedBox(height: 12),
          Entrance(
            index: 1,
            child: Text(
              'Save a look from the studio, or after a show, and it '
              'joins your lookbook here.',
              style: Txt.body(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lookbook extends StatelessWidget {
  const _Lookbook({
    required this.looks,
    required this.index,
    required this.onAdvance,
    required this.onSelect,
  });

  final List<SavedLook> looks;
  final int index;
  final VoidCallback onAdvance;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.read(context);
    final current = looks[index];
    final frameHeight = MediaQuery.sizeOf(context).height * 0.46;
    return ListView(
      key: const Key('lookbook'),
      padding: const EdgeInsets.fromLTRB(kMargin, 8, kMargin, 32),
      children: [
        Entrance(
          index: 0,
          child: Semantics(
            label: 'Show the next look',
            button: true,
            child: GestureDetector(
              onTap: onAdvance,
              child: Container(
                height: frameHeight,
                color: Palette.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AnimatedSwitcher(
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  child: ModelView(
                    key: ValueKey(current),
                    look: current.look,
                    showFloor: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          current.score == null
              ? current.title
              : '${current.title}, ${current.score} points',
          style: Txt.small(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Wear this look',
                onPressed: () {
                  game.setLook(current.look);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Your model is wearing this look')));
                },
              ),
            ),
            const SizedBox(width: 24),
            TextLink('Delete', onTap: () => game.deleteFromGallery(current)),
          ],
        ),
        const SizedBox(height: 40),
        Text('All looks', style: Txt.lead()),
        const SizedBox(height: 8),
        for (var i = 0; i < looks.length; i++)
          Semantics(
            selected: i == index,
            button: true,
            child: Pressable(
              onTap: () => onSelect(i),
              child: Container(
                color: i == index ? Palette.accent : Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(looks[i].title,
                          style: Txt.body(
                              i == index ? Palette.accentInk : Palette.ink)),
                    ),
                    if (looks[i].score != null)
                      Text('${looks[i].score}',
                          style: Txt.small(i == index
                                  ? Palette.accentInk
                                  : Palette.muted)
                              .copyWith(fontFeatures: Txt.tabular)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
