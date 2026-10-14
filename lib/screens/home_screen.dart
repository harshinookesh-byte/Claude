import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'challenge_select_screen.dart';
import 'gallery_screen.dart';
import 'studio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final ads = AdScope.of(context);
    return Scaffold(
      backgroundColor: StudioBackground.bottomColor,
      bottomNavigationBar: const BannerSlot(),
      body: StudioBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                const Row(
                  children: [LevelBadge(), Spacer(), CoinChip()],
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (r) =>
                      const LinearGradient(colors: pinkGradient)
                          .createShader(r),
                  child: const Text(
                    'Fashion Star',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Text('Dress Up Show',
                    style: TextStyle(
                        color: Color(0xFF8E4FC2),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                Colors.white.withAlpha(220),
                                Colors.white.withAlpha(0),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ModelView(look: game.current),
                      ),
                      Positioned(
                        right: 0,
                        top: 16,
                        child: _Stat(label: 'Wins', value: '${game.wins}'),
                      ),
                      Positioned(
                        left: 0,
                        top: 16,
                        child: _Stat(label: 'Shows', value: '${game.shows}'),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  label: 'FASHION SHOW',
                  icon: Icons.emoji_events,
                  height: 62,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ChallengeSelectScreen())),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.brush,
                        label: 'Studio',
                        color: const Color(0xFFFF6FB5),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const StudioScreen())),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: const Color(0xFF9C6BFF),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GalleryScreen())),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.card_giftcard,
                        label: game.dailyAvailable ? 'Daily Gift' : 'Claimed',
                        color: const Color(0xFFFFA726),
                        badge: game.dailyAvailable,
                        onTap: game.dailyAvailable
                            ? () {
                                game.claimDaily();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Daily gift: +${GameState.dailyBonus} coins!'),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.ondemand_video,
                        label: 'Free Coins',
                        color: const Color(0xFF26A69A),
                        badge: ads.rewardedReady,
                        onTap: ads.rewardedReady
                            ? () => _watchForCoins(context)
                            : null,
                      ),
                    ),
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

Future<void> _watchForCoins(BuildContext context) async {
  final earned = await AdScope.read(context).showRewarded();
  if (!earned || !context.mounted) return;
  GameScope.read(context).addCoins(GameState.adCoins);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Thanks for watching! +${GameState.adCoins} coins')));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5B2A86))),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Badge(
                isLabelVisible: badge,
                smallSize: 10,
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
