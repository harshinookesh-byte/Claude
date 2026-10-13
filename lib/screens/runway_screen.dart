import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/challenges.dart';
import '../logic/scoring.dart';
import '../models/look.dart';
import '../state/game_state.dart';
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
      backgroundColor: const Color(0xFF1A0B2E),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _RunwayBackdrop(),
            SafeArea(
              child: switch (_stage) {
                _Stage.playerWalk => _walkView(widget.look, 'You'),
                _Stage.rivalWalk => _walkView(_rival, _rivalName),
                _Stage.judging || _Stage.result => _resultsView(),
              },
            ),
            if (_stage == _Stage.result && _won)
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

  Widget _walkView(Look look, String name) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(widget.challenge.title.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w900,
                letterSpacing: 3)),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        Expanded(
          child: AnimatedBuilder(
            animation: _walk,
            builder: (context, child) {
              final t = Curves.easeOut.transform(_walk.value);
              // Walk towards the camera with a little sway.
              final sway = math.sin(_walk.value * math.pi * 6) * 0.02;
              return Align(
                alignment: Alignment(sway, -0.9 + 0.9 * t),
                child: FractionallySizedBox(
                  heightFactor: 0.45 + 0.5 * t,
                  child: child,
                ),
              );
            },
            child: ModelView(look: look, showStage: false),
          ),
        ),
        AnimatedBuilder(
          animation: _walk,
          builder: (_, __) => Opacity(
            // Camera flashes.
            opacity: (math.sin(_walk.value * 40) > 0.85) ? 1 : 0,
            child: const Icon(Icons.flash_on, color: Colors.white, size: 36),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Tap to skip', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _resultsView() {
    final done = _stage == _Stage.result;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            done
                ? (_won ? 'YOU WIN!' : '$_rivalName wins!')
                : 'The judges are scoring...',
            style: TextStyle(
              color: done && _won ? const Color(0xFFFFD54F) : Colors.white,
              fontSize: done ? 34 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _Contestant(
                    name: 'You',
                    look: widget.look,
                    score: _playerScore,
                    highlight: done && _won,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Text('VS',
                      style: TextStyle(
                          color: Color(0xFFFF4FA3),
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                ),
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
                ? const SizedBox(height: 120)
                : Column(
                    key: const ValueKey('done'),
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on,
                              color: Color(0xFFFFC107)),
                          const SizedBox(width: 6),
                          Text('+$_earned coins',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                minimumSize: const Size.fromHeight(52),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _saved
                                  ? null
                                  : () {
                                      GameScope.read(context).saveToGallery(
                                        widget.look,
                                        title: widget.challenge.title,
                                        score: _playerScore.total,
                                      );
                                      setState(() => _saved = true);
                                    },
                              icon: Icon(
                                  _saved ? Icons.check : Icons.bookmark_add),
                              label: Text(_saved ? 'Saved' : 'Save Look'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: 'CONTINUE',
                              height: 52,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
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
    return Column(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: highlight ? const Color(0xFFFFD54F) : Colors.white12,
                width: 3,
              ),
              color: Colors.white.withAlpha(highlight ? 30 : 12),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                if (highlight)
                  const Icon(Icons.emoji_events, color: Color(0xFFFFD54F)),
                Expanded(child: ModelView(look: look, showStage: false)),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++)
          _JudgeRow(
            label: _judges[i],
            mark: score.judgeMarks[i],
            delay: Duration(milliseconds: 400 * i),
          ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score.total.toDouble()),
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            '${v.round()}',
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD54F) : Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _JudgeRow extends StatelessWidget {
  const _JudgeRow(
      {required this.label, required this.mark, required this.delay});

  final String label;
  final int mark;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: FutureBuilder(
              future: Future<void>.delayed(delay),
              builder: (context, snap) => TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0,
                    end: snap.connectionState == ConnectionState.done
                        ? mark / 10
                        : 0),
                duration: const Duration(milliseconds: 900),
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    color: const Color(0xFFFF4FA3),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text('$mark',
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

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
    // Runway in perspective.
    final runway = Path()
      ..moveTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.58, h * 0.18)
      ..lineTo(w * 0.95, h)
      ..lineTo(w * 0.05, h)
      ..close();
    canvas.drawPath(
      runway,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B1F5C), Color(0xFF8E2C6E)],
        ).createShader(Offset.zero & size),
    );
    // Spotlights.
    for (final x in [0.15, 0.85]) {
      final beam = Path()
        ..moveTo(w * x, 0)
        ..lineTo(w * 0.5 - 60, h * 0.85)
        ..lineTo(w * 0.5 + 60, h * 0.85)
        ..close();
      canvas.drawPath(beam, Paint()..color = Colors.white.withAlpha(18));
    }
    // Audience lights.
    final rnd = math.Random(3);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, h * (0.2 + rnd.nextDouble() * 0.8)),
        1 + rnd.nextDouble() * 1.5,
        Paint()..color = Colors.white.withAlpha(40 + rnd.nextInt(80)),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const _colors = [
    Color(0xFFFF4FA3),
    Color(0xFFFFD54F),
    Color(0xFF7C4DFF),
    Color(0xFF00E5FF),
    Color(0xFF76FF03),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 80; i++) {
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
