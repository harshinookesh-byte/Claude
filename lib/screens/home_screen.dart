import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../state/game_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'challenge_select_screen.dart';
import 'gallery_screen.dart';
import 'studio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final ads = AdScope.of(context);
    final record = game.shows == 0
        ? 'Dress the model, then win three judges over on the runway.'
        : 'Dress the model, then win three judges over on the runway. '
            '${game.wins} ${game.wins == 1 ? 'win' : 'wins'} from '
            '${game.shows} ${game.shows == 1 ? 'show' : 'shows'} so far.';
    return Scaffold(
      bottomNavigationBar: const BannerSlot(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kMargin, 12, kMargin, 0),
              child: Entrance(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Fashion Star', style: Txt.display()),
                    ),
                    const SizedBox(height: 6),
                    const CoinCount(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Entrance(
                  index: 1,
                  child: Center(child: ModelView(look: game.current)),
                ),
              ),
            ),
            Container(
              color: Palette.surface,
              padding: const EdgeInsets.fromLTRB(kMargin, 20, kMargin, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Entrance(index: 2, child: LevelMeter()),
                  const SizedBox(height: 16),
                  Entrance(
                    index: 3,
                    child: Text(record, style: Txt.body()),
                  ),
                  const SizedBox(height: 20),
                  Entrance(
                    index: 4,
                    child: PrimaryButton(
                      label: 'Start a show',
                      onPressed: () =>
                          _open(context, const ChallengeSelectScreen()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Entrance(
                    index: 5,
                    child: Wrap(
                      spacing: 24,
                      children: [
                        TextLink('Studio',
                            onTap: () => _open(context, const StudioScreen())),
                        TextLink('Gallery',
                            onTap: () => _open(context, const GalleryScreen())),
                        TextLink(
                          game.dailyAvailable ? 'Daily gift' : 'Gift claimed',
                          onTap: game.dailyAvailable
                              ? () => _claimDaily(context)
                              : null,
                        ),
                        TextLink(
                          'Free coins',
                          onTap: ads.rewardedReady
                              ? () => _watchForCoins(context)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _claimDaily(BuildContext context) {
  GameScope.read(context).claimDaily();
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Daily gift: ${GameState.dailyBonus} coins added')));
}

Future<void> _watchForCoins(BuildContext context) async {
  final earned = await AdScope.read(context).showRewarded();
  if (!earned || !context.mounted) return;
  GameScope.read(context).addCoins(GameState.adCoins);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Thanks for watching. ${GameState.adCoins} coins added')));
}
