import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../data/challenges.dart';
import '../logic/scoring.dart';
import '../models/look.dart';
import '../state/game_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

enum _Stage { playerWalk, rivalWalk, judging, result }

/// The fashion show: both models walk the runway, judges score them and a
/// winner is announced.
class RunwayScreen extends StatefulWidget {
  const RunwayScreen({super.key, required this.challenge, required this.look});

  final Challenge challenge;
  final Look look;

  @override
  State<RunwayScreen> createState() => _RunwayScreenState();
}

class _RunwayScreenState extends State<RunwayScreen>
    with TickerProviderStateMixin {
  late final _rnd = math.Random();
  late final String _rivalName =
      opponentNames[_rnd.nextInt(opponentNames.length)];
  late final Look _rival;
  late final ScoreCard _playerScore;
  late final ScoreCard _rivalScore;
  late final AnimationController _walk = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  _Stage _stage = _Stage.playerWalk;
  int _earned = 0;
  bool _saved = false;
  bool _doubled = false;
  bool _leaving = false;

  bool get _won => _playerScore.total >= _rivalScore.total;

  @override
  void initState() {
    super.initState();
    final game = GameScope.read(context);
    // Rivals get sharper as the player levels up.
    final skill = (0.35 + game.level * 0.07).clamp(0.35, 0.85);
    _rival = rivalLook(widget.challenge, _rnd, skill: skill);
    _playerScore = scoreLook(widget.look, widget.challenge);
    _rivalScore = scoreLook(_rival, widget.challenge);
    // Driven by status rather than awaiting forward(): skipping a walk jumps
    // the controller to the end, which cancels any pending TickerFuture.
    _walk.addStatusListener(_onWalkStatus);
    _walk.forward();
  }

  void _onWalkStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_stage == _Stage.playerWalk) {
      setState(() => _stage = _Stage.rivalWalk);
      _walk.forward(from: 0);
    } else if (_stage == _Stage.rivalWalk) {
      setState(() => _stage = _Stage.judging);
      _judge();
    }
  }

  Future<void> _judge() async {
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    final earned = GameScope.read(context)
        .recordShow(won: _won, reward: widget.challenge.reward);
    setState(() {
      _earned = earned;
      _stage = _Stage.result;
    });
    if (_won) _confetti.repeat();
  }

  Future<void> _doubleCoins() async {
    final earned = await AdScope.read(context).showRewarded();
    if (!earned || !mounted) return;
    GameScope.read(context).addCoins(_earned);
    setState(() {
      _earned *= 2;
      _doubled = true;
    });
  }

  Future<void> _continue() async {
    setState(() => _leaving = true);
    // Interstitials only ever appear between shows, and are paced.
    await AdScope.read(context).onShowFinished();
    if (mounted) Navigator.of(context).pop();
  }

  void _skip() {
    if (_stage == _Stage.playerWalk || _stage == _Stage.rivalWalk) {
      _walk.value = 1;
    }
  }

  @override
  void dispose() {
    _walk.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_stage == _Stage.playerWalk || _stage == _Stage.rivalWalk)
              const _RunwayBackdrop(),
            SafeArea(
              child: switch (_stage) {
                _Stage.playerWalk => _walkView(widget.look, 'You'),
                _Stage.rivalWalk => _walkView(_rival, _rivalName),
                _Stage.judging || _Stage.result => _resultsView(),
              },
            ),
            if (_stage == _Stage.result && _won && !reduceMotion(context))
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (_, __) =>
                      CustomPaint(painter: _ConfettiPainter(_confetti.value)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The show's name stays pinned while each model walks beneath it.
  Widget _walkView(Look look, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(kMargin, 16, kMargin, 0),
          child:
              Text(widget.challenge.title, maxLines: 2, style: Txt.display()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(kMargin, 8, kMargin, 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              name == 'You' ? 'You walk first' : '$name walks next',
              key: ValueKey(name),
              style: Txt.lead(),
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _walk,
            builder: (context, child) {
              final t = reduceMotion(context)
                  ? 1.0
                  : Curves.easeOut.transform(_walk.value);
              // Walk towards the camera with a little sway.
              final sway = reduceMotion(context)
                  ? 0.0
                  : math.sin(_walk.value * math.pi * 6) * 0.02;
              return Align(
                alignment: Alignment(sway, -1 + 1.0 * t),
                child: FractionallySizedBox(
                  heightFactor: 0.5 + 0.48 * t,
                  child: child,
                ),
              );
            },
            child: ModelView(look: look, showFloor: false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(kMargin, 8, kMargin, 12),
          child: Text('Tap to skip',
              textAlign: TextAlign.center, style: Txt.small()),
        ),
      ],
    );
  }

  Widget _resultsView() {
    final done = _stage == _Stage.result;
    final ads = AdScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kMargin, 16, kMargin, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              done
                  ? (_won ? 'You win' : '$_rivalName wins')
                  : 'The judges are scoring',
              key: ValueKey(done),
              style: Txt.head(),
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.challenge.title, style: Txt.small()),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Contestant(
                    name: 'You',
                    look: widget.look,
                    score: _playerScore,
                    highlight: done && _won,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Contestant(
                    name: _rivalName,
                    look: _rival,
                    score: _rivalScore,
                    highlight: done && !_won,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !done
                ? const SizedBox(height: 148)
                : Column(
                    key: const ValueKey('done'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text('$_earned coins added',
                                style: Txt.lead()
                                    .copyWith(fontFeatures: Txt.tabular)),
                          ),
                          if (!_doubled && ads.rewardedReady)
                            Flexible(
                              child: TextLink('Double them with an ad',
                                  onTap: _doubleCoins),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Continue',
                        onPressed: _leaving ? null : _continue,
                      ),
                      Center(
                        child: TextLink(
                          _saved ? 'Saved to your looks' : 'Save this look',
                          onTap: _saved
                              ? null
                              : () {
                                  GameScope.read(context).saveToGallery(
                                    widget.look,
                                    title: widget.challenge.title,
                                    score: _playerScore.total,
                                  );
                                  setState(() => _saved = true);
                                },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Contestant extends StatelessWidget {
  const _Contestant({
    required this.name,
    required this.look,
    required this.score,
    required this.highlight,
  });

  final String name;
  final Look look;
  final ScoreCard score;
  final bool highlight;

  static const _judges = ['Theme', 'Style', 'Makeup'];

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Palette.accentInk : Palette.ink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: highlight ? Palette.accent : Palette.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Txt.lead(fg)),
          Expanded(child: ModelView(look: look, showFloor: false)),
          const SizedBox(height: 8),
          for (var i = 0; i < 3; i++)
            _JudgeRow(
              label: _judges[i],
              mark: score.judgeMarks[i],
              delay: Duration(milliseconds: 400 * i),
              ink: fg,
              track: highlight ? Palette.muted : Palette.raised,
            ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score.total.toDouble()),
            duration: reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 2000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.round()}',
              style: Txt.head(fg).copyWith(fontFeatures: Txt.tabular),
            ),
          ),
        ],
      ),
    );
  }
}

class _JudgeRow extends StatefulWidget {
  const _JudgeRow({
    required this.label,
    required this.mark,
    required this.delay,
    required this.ink,
    required this.track,
  });

  final String label;
  final int mark;
  final Duration delay;
  final Color ink;
  final Color track;

  @override
  State<_JudgeRow> createState() => _JudgeRowState();
}

class _JudgeRowState extends State<_JudgeRow> {
  // Started once, so rebuilds (e.g. an ad loading) don't restart the reveal.
  late final Timer _reveal = Timer(widget.delay, () {
    if (mounted) setState(() => _shown = true);
  });
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _reveal;
  }

  @override
  void dispose() {
    _reveal.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = widget.mark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(widget.label, style: Txt.small(widget.ink)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _shown ? mark / 10 : 0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, __) => SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: v,
                  color: widget.ink,
                  backgroundColor: widget.track,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text('$mark',
                textAlign: TextAlign.end,
                style:
                    Txt.small(widget.ink).copyWith(fontFeatures: Txt.tabular)),
          ),
        ],
      ),
    );
  }
}

/// The runway: one flat shape a tone step above the ground, narrowing
/// towards the back of the room.
class _RunwayBackdrop extends StatelessWidget {
  const _RunwayBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter());
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final runway = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.98, h)
      ..lineTo(w * 0.02, h)
      ..close();
    canvas.drawPath(runway, Paint()..color = Palette.surface);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const _colors = [Palette.ink, Palette.muted];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 60; i++) {
      final speed = 0.6 + rnd.nextDouble();
      final x =
          rnd.nextDouble() * size.width + math.sin((t + i) * math.pi * 2) * 12;
      final y = ((rnd.nextDouble() + t * speed) % 1.0) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 6 + i) % (math.pi * 2));
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4),
          Paint()..color = _colors[i % _colors.length]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
