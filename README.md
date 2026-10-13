# Fashion Star – Dress Up Show (Flutter clone)

A Flutter clone of the Google Play game
[**Fashion Star: Dress Up Show**](https://play.google.com/store/apps/details?id=com.gofive.indian.makeup.fashion.dress.up)
(package `com.gofive.indian.makeup.fashion.dress.up`, by "Dress Up Games for Girls" / Pion Studios).

## Research summary of the original

| | |
|---|---|
| Genre | Simulation / casual dress-up, rated *Everyone* |
| Popularity | 10M+ downloads, 4.5★ from ~115K reviews (Oct 2026) |
| Monetisation | Ads (incl. rewarded ads) + in-app purchases |
| Core loop | Makeup salon → dress the model → walk the runway in a themed fashion battle against a rival → judges vote → earn coins → unlock outfits, climb levels |
| Content | 800+ outfits, accessories and hairstyles: red carpet, street style, weddings, princess, plus Indian fashion (saree, lehenga, jewellery) |
| Makeup | Skin tone, eyes, lips, blush, runway makeup |
| Player complaints | Too many ads, no way to save progress, wish-list of more Indian items (separate **nose ring / nath**, **bindi**) |

## What this clone implements

- **Makeup salon**: skin tone, hair colour, eye colour, eyeshadow, winged liner, lashes, lipstick and blush.
- **Wardrobe**: about 120 items in 13 slots: hair, dresses, tops, bottoms, shoes, necklace, earrings, headpiece, **bindi**, **nose ring**, bangles, bags and glasses. It includes Indian wear (silk & chiffon sarees, bridal lehenga, anarkali, salwar kameez, choli, kurti, churidar, jutti, kundan, jhumka, maang tikka, nath, gajra, glass bangles, potli) and western wear (gowns, ball gowns, minis, blazers, jeans and more).
- **Fashion shows**: 9 themed challenges (Street Style, Mehendi Night, Beach Holiday, Boss Lady, Diwali Festival, Glitter Party, Royal Indian Wedding, Red Carpet Gala, Princess Ball) that unlock as you level up. You and an AI rival walk an animated runway (tap to skip). Three judges score Theme, Style and Makeup, and the winner gets confetti and coins.
- **Economy**: coins, XP and levels, premium items you unlock with coins, a daily gift, and rivals that get tougher as you level up.
- **Style Studio and Gallery**: style freely, use undo, randomise ("Surprise me") or reset, save looks to a gallery, and wear a saved look again.
- **Progress is saved** on the device (shared_preferences). No ads.

All artwork is drawn in code (`lib/widgets/model_painter.dart`) with a `CustomPainter`, so there are no image assets. Item thumbnails are rendered by the same painter.

## Project layout

```
lib/
  main.dart                  app entry, theme
  models/                    FashionItem, Slot, Look, Makeup, SavedLook
  data/catalog.dart          all items + makeup palettes
  data/challenges.dart       fashion-show themes
  logic/scoring.dart         judges' scoring and rival look generator
  state/game_state.dart      coins/XP/unlocks/gallery + persistence
  widgets/model_painter.dart vector model, clothes, hair, makeup, jewellery
  screens/                   home, challenge select, studio, runway, gallery
test/                        unit tests + widget tests of the full flows
```

## Run

```bash
flutter pub get
flutter run            # Android / iOS / web
flutter test
```

Built and tested with Flutter 3.27 (Dart 3.6).

## Build the Android APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

The Android build uses Gradle 8.10.2, AGP 8.7.3 and Kotlin 2.1.0, so it works with JDK 17 or 21.
The release APK is signed with the debug key (fine for sideloading). Set up your own
signing key before publishing to Google Play.
