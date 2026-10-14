import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../data/challenges.dart';
import '../state/game_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'studio_screen.dart';

/// The season's shows as a running order: one size of type, the reward
/// right-aligned, shows still to come set in the soft ink.
class ChallengeSelectScreen extends StatelessWidget {
  const ChallengeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final open = challenges.where((c) => game.level >= c.unlockLevel).toList();
    final later = challenges.where((c) => game.level < c.unlockLevel).toList();
    var i = 0;
    return Scaffold(
      bottomNavigationBar: const BannerSlot(),
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Fashion shows'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kMargin, 8, kMargin, 32),
                children: [
                  Entrance(
                    index: i++,
                    child: Text('Pick tonight’s show', style: Txt.head()),
                  ),
                  const SizedBox(height: 8),
                  Entrance(
                    index: i++,
                    child: Text(
                      'Each show has a theme. The judges score how well your '
                      'look fits it, how complete it is, and the makeup.',
                      style: Txt.body(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  for (final c in open)
                    Entrance(
                      index: i++,
                      child: _ShowRow(
                        challenge: c,
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                              builder: (_) => StudioScreen(challenge: c)),
                        ),
                      ),
                    ),
                  if (later.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Text('Coming up', style: Txt.lead()),
                    const SizedBox(height: 12),
                    for (final c in later)
                      _ShowRow(
                        challenge: c,
                        onTap: () =>
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('${c.title} opens at level '
                                    '${c.unlockLevel}.'))),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final locked = game.level < challenge.unlockLevel;
    final ink = locked ? Palette.muted : Palette.ink;
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(challenge.title, style: Txt.lead(ink))),
                  const SizedBox(width: 12),
                  Text(
                    locked
                        ? 'Level ${challenge.unlockLevel}'
                        : '${challenge.reward} coins',
                    style: Txt.small(ink).copyWith(fontFeatures: Txt.tabular),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(challenge.brief, style: Txt.small()),
            ],
          ),
        ),
      ),
    );
  }
}
