# Session Handoff — 2026-08-25 (Jackaroo v1.0)

## TL;DR
Built a complete Flutter Jackaroo game from scratch in one session: pure rules
engine (19 tests), bots, house-rule toggles, EN/AR, synthesized sounds, dark
felt-and-gold UI, pass-and-play cover, PWA. Source on GitHub `hamoodigan/jackaroo`
(`main`), web build on `gh-pages` → **https://hamoodigan.github.io/jackaroo/**.
Cousins on iPhone/Android open that link → Safari/Chrome "Add to Home Screen".

## Why this exists
Cousins' Jackaroo app forces the Jack to swap one of *your own* marbles with an
opponent's; on a physical board they swap ANY two marbles. `RuleSet.jackSwapAny`
(default ON) = board rule; OFF = app rule. Other toggles: 5 moves any marble,
King burns path, can burn partner, 7 split.

## What went right
- Engine designed state-first (`GameState.toJson()`), so online play can sync the
  same document later. Engine returns `MoveEvent`s → UI animates from them.
- Relative marble positions (`Pos`: -1 base, 0..75 track from own entry, 100+ home)
  make the classic "4 back from entry, then enter home" trick fall out naturally.
- Bot-vs-bot full-game test guarantees no dead-lock in dealing/turn flow.
- Visual verification through windows-mcp screenshots caught nothing wrong in the
  final build; a played Ace exit + 3 bot turns worked in Chrome.

## What went wrong / gotchas
- Bash heredocs with `'EOF'` failed on Dart files containing unicode (`♠`) — use
  the Write tool or python for Dart files.
- `Obx` reading `Get.locale` (non-observable) → red GetX error box. Fixed; but the
  error kept showing because Chrome cached the old bundle → **hard refresh
  (Ctrl+Shift+R)** before assuming a fix didn't land.
- `flutter build web --base-href /jackaroo/` from Git Bash → "base-href should
  start and end with /" (MSYS path mangling). Use `MSYS_NO_PATHCONV=1`.
- No global git identity on this PC → set repo-local `user.name/email`
  (done in both the project repo and `build/web`'s throwaway repo).
- `flutter run -d chrome` in background can't take `r`/`R`; relaunch to see changes.

## Current state
- Web: LIVE (Pages status was "building" at handoff; check the URL).
- Android APK: `flutter build apk --release` was started at the end of the
  session — check `build/app/outputs/flutter-apk/app-release.apk`. If Gradle fails
  with the jni/`kotlin()` error, pin like Ludo (`dependency_overrides:
  path_provider_android: 2.2.17`) — this project has no url_launcher.
- iOS: `ios/` folder exists; a real build needs a Mac + $99 Apple account. PWA is
  the free route.

## Not yet verified
- Jack swap / 7-split / discard flows in the real UI (engine-tested only).
- Arabic RTL layout, landscape layout, small phones.
- Audio on iOS Safari (needs a user gesture first — first tap on Play).

## Next steps (in order)
1. Play a full game in the browser, especially J / 7 / 5-on-opponent flows.
2. Online play: Firebase RTDB free tier + anonymous auth; room code; only `turn`
   seat may write; hands under `hands/{uid}` readable only by that uid.
3. Optional: sync to Ludo-style history/stats, more themes.

## Key files
- `lib/domain/engine/jackaroo_engine.dart` — all rules; `legalMoves(seat)` + `apply(move)`
- `lib/domain/engine/bot_engine.dart` — heuristic AI (easy/normal/hard)
- `lib/presentation/controllers/game_controller.dart` — tap flow: card → marble → target (→ second marble/target for 7-split; marble for J)
- `lib/presentation/widgets/board_geometry.dart` / `board_painter.dart` / `board_view.dart`
- `lib/core/localization/app_translations.dart` — EN + AR strings incl. rules text
- `tool/make_sounds.dart` — regenerates `assets/sounds/*.wav`
- Redeploy: `MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/jackaroo/"`,
  then in `build/web`: `git init`, commit, `git push -f https://github.com/hamoodigan/jackaroo.git gh-pages`
