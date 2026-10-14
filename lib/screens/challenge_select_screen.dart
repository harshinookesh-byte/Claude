import 'package:flutter/material.dart';

import '../data/challenges.dart';
import '../ads/ad_service.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'studio_screen.dart';

class ChallengeSelectScreen extends StatelessWidget {
  const ChallengeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Scaffold(
      bottomNavigationBar: AdScope.of(context).banner(),
      appBar: AppBar(
        title: const Text('Fashion Shows',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        actions: const [CoinChip(), SizedBox(width: 12)],
      ),
      extendBodyBehindAppBar: true,
      body: StudioBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = challenges[i];
              final locked = game.level < c.unlockLevel;
              return _ChallengeCard(
                challenge: c,
                locked: locked,
                onTap: locked
                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Reach level ${c.unlockLevel} to unlock!')))
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => StudioScreen(challenge: c)),
                        ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.locked,
    required this.onTap,
  });

  final Challenge challenge;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: locked
                ? [Colors.grey.shade500, Colors.grey.shade400]
                : challenge.gradient,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withAlpha(60),
                  child: Icon(locked ? Icons.lock : challenge.icon,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        locked
                            ? 'Unlocks at level ${challenge.unlockLevel}'
                            : challenge.brief,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFE082)),
                    Text('${challenge.reward}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
