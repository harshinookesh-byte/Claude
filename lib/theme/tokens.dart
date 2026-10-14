import 'package:flutter/material.dart';

/// Design tokens, from the taste-skill direction sheet "The pinned poster"
/// (palette "Burgundy and bubblegum", type Hanken Grotesk).
///
/// Every colour and text style in the UI comes from here. Surfaces are told
/// apart by a step in tone, never by a line or a shadow; the one accent marks
/// the action and the selected state.
abstract final class Palette {
  /// The ground: most of every screen.
  static const ground = Color(0xFF3D0012);

  /// One tone step up: panels, tiles, the runway.
  static const surface = Color(0xFF4D0519);

  /// A second step, for things sitting on a surface (tiles in the tray,
  /// the empty part of a progress bar).
  static const raised = Color(0xFF5E0B25);

  /// Text and the strongest marks.
  static const ink = Color(0xFFFF99D3);

  /// Secondary text; still passes contrast on the ground.
  static const muted = Color(0xFFC77AA0);

  /// The one accent (the action, the selected state) and the text set on it.
  static const accent = ink;
  static const accentInk = ground;
}

/// Five type sizes, no more. One very large, one small, little in between.
abstract final class Steps {
  static const small = 14.0;
  static const body = 17.0;
  static const lead = 22.0;
  static const head = 34.0;
  static const display = 56.0;
}

abstract final class Txt {
  static const family = 'Hanken Grotesk';

  static TextStyle _display(double size, Color color) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05 * size,
        height: 0.95,
        color: color,
      );

  static TextStyle _text(double size, Color color,
          {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.005 * size,
        height: 1.45,
        color: color,
      );

  static TextStyle display([Color color = Palette.ink]) =>
      _display(Steps.display, color);
  static TextStyle head([Color color = Palette.ink]) =>
      _display(Steps.head, color);
  static TextStyle lead([Color color = Palette.ink]) =>
      _text(Steps.lead, color, weight: FontWeight.w500)
          .copyWith(letterSpacing: -0.02 * Steps.lead, height: 1.15);
  static TextStyle body([Color color = Palette.ink]) =>
      _text(Steps.body, color);
  static TextStyle bodyMedium([Color color = Palette.ink]) =>
      _text(Steps.body, color, weight: FontWeight.w500);
  static TextStyle small([Color color = Palette.muted]) =>
      _text(Steps.small, color);

  /// Numbers that change in place (coins, scores) keep their width.
  static const tabular = [FontFeature.tabularFigures()];
}

/// One corner radius for every component: square.
const kRadius = BorderRadius.zero;

/// One pair of page margins.
const kMargin = 20.0;

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    surface: Palette.ground,
    onSurface: Palette.ink,
    surfaceContainerLowest: Palette.ground,
    surfaceContainerLow: Palette.surface,
    surfaceContainer: Palette.surface,
    surfaceContainerHigh: Palette.surface,
    surfaceContainerHighest: Palette.raised,
    onSurfaceVariant: Palette.muted,
    primary: Palette.accent,
    onPrimary: Palette.accentInk,
    secondary: Palette.accent,
    onSecondary: Palette.accentInk,
    outline: Palette.muted,
    outlineVariant: Palette.raised,
    error: Palette.ink,
    onError: Palette.ground,
  );
  const square = RoundedRectangleBorder(borderRadius: kRadius);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Txt.family,
    scaffoldBackgroundColor: Palette.ground,
    splashFactory: NoSplash.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: Txt.family,
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
    iconTheme: const IconThemeData(color: Palette.ink),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: square,
      titleTextStyle: Txt.lead(),
      contentTextStyle: Txt.body(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.ink,
      contentTextStyle: Txt.body(Palette.accentInk),
      behavior: SnackBarBehavior.floating,
      shape: square,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.accent,
        foregroundColor: Palette.accentInk,
        disabledBackgroundColor: Palette.raised,
        disabledForegroundColor: Palette.muted,
        shape: square,
        elevation: 0,
        textStyle: Txt.bodyMedium(),
        minimumSize: const Size(64, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.ink,
        disabledForegroundColor: Palette.muted,
        shape: square,
        textStyle: Txt.body(),
        minimumSize: const Size(48, 48),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.accent,
      linearTrackColor: Palette.raised,
    ),
  );
}
