# Session Handoff — 2026-08-25

> **Projects Hub** (all handoffs in one dashboard): run `Desktop\Work\Projects\Open-Projects-Hub.cmd`, then open http://localhost:4680/ — this file shows up there as a card.

## TL;DR
Built a complete Flutter Jackaroo game from zero in one session (offline pass-and-play + bots, online rooms, card guide, EN/AR), iterated live with the user on the board shape three times until it matched a photo of the real octagonal board, then added the user's house rules for 10 and Queen. Everything is deployed: web PWA at https://hamoodigan.github.io/jackaroo/ (GitHub `hamoodigan/jackaroo`, source `main`, build `gh-pages`), APK at `build/app/outputs/flutter-apk/app-release.apk` (52 MB). 53 tests green; online play verified host↔guest in two browser windows on the real broker.

## What went right
- Engine-first design: `lib/domain/engine/jackaroo_engine.dart` is pure (`legalMoves(seat)` + `apply(move)` → `MoveEvent`s), `GameState.toJson()` is the sync document. That made online play a thin layer instead of a rewrite.
- Relative marble positions (`Pos`: -1 pocket, 0..75 from own base hole, 100+ home) make the "4 back from base then enter home" trick natural; `entryOffset = 0` (segment starts at the base hole).
- Tests that pay off: `test/card_flow_test.dart` drives every card through the real tap flow via `GameController` (`refreshTurn()` / `settle()` hooks); `test/online_flow_test.dart` runs host + client controllers over an in-memory fake broker; `test/broker_connectivity_test.dart` does a live HiveMQ round-trip; `test/engine_test.dart` includes a bot-vs-bot full game.
- Board geometry traced from the user's photo with a blob detector (python/PIL in the scratchpad) → `board_geometry.dart` template for one corner rotated 90° per seat; `test/geometry_test.dart` guards pitch/overlap/rotation.
- Online = public MQTT broker (`broker.hivemq.com`, `mqtt_client`), zero setup: retained `lobby`/`state`, `moves` host→all, `intent` client→host, host authoritative and runs bots. Room code = 4 letters.
- windows-mcp screenshots of Chrome were the effective verification loop; two side-by-side windows (Win+Right snap) for host/guest.

## What went wrong / friction
- Board shape: first a square ring going counter-clockwise, then a plus/cross with arms — user rejected both ("incorrectly shaped", "clockwise", "marbles outside the cross", "one corner over clockwise"). Only the photo the user opened (GROIC board on noon.com) settled it. Cost ~2 hours.
- Online silently broke on first real test: `Get.offNamed('/game')` from the lobby made GetX SmartManagement dispose the `GameController` created on that route; widgets kept a stale reference and `_run` bailed on `_disposed` before publishing. Diagnosed by probing the broker's retained `state` (seq stayed 0). Fixed with `Get.put(..., permanent: true)` in both `online_controller._launch` and `setup_screen._start`.
- `Obx` reading `Get.locale` (not observable) → red error box; then Chrome's cached bundle kept showing it after the fix.
- Git Bash heredocs failed twice on Dart content (unicode ♠/quotes) → switched to Write tool / python script files in the scratchpad.
- `flutter build web --base-href /jackaroo/` errored in Git Bash (MSYS path mangling) → `MSYS_NO_PATHCONV=1`.
- No global git identity on the PC → first repo create failed; identity set repo-locally (also needed in the throwaway `build/web` repo).
- New 10/Queen skip rule created a state where a seat has no cards mid-round → bot game test hung on `assert(moves.isNotEmpty)`; fixed with `_advanceTurn` passing over empty hands.
- `flutter run -d chrome` from a background shell can't hot reload; every change needed a relaunch on a new port (5320…5326) and re-navigating tabs.

## Avoid next time
- Do not redesign the board from memory again — ask for a photo first. Geometry numbers are in `board_geometry.dart` comments and this file.
- Never launch a screen that owns a `Get.put` controller with `offNamed`/`offAll` unless the controller is `permanent: true`.
- Don't write Dart via bash heredocs on this machine; use the Write tool or a `.py` patch file run with `python file.py`.
- Hard-refresh (Ctrl+Shift+R) Chrome before concluding a fix "didn't work".
- Don't trust the terminal log for web runtime errors — they only appear in the browser console (F12).
- User preferences voiced: board must be the real octagon; marbles move clockwise; waiting marbles live outside the loop and only home-bound marbles enter the middle; Jack swaps any two marbles by default; 10 = move OR force-discard+skip; Queen = move OR blind steal+skip; wants a card guide and zero-cost online play.

## Notes, tips & gotchas
- Windows 11, Git Bash for the Bash tool (MSYS path conversion!), PowerShell 5.1 also available. Flutter 3.44.7. No global git user.name/email.
- Run: `flutter run -d chrome --web-port=NNNN` (launch in background with `( … & )` and poll the log for "Flutter run key commands").
- Redeploy web: `MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/jackaroo/"`, then in `build/web`: `rm -rf .git && git init && git config user.email/name && git checkout -b gh-pages && git add -A && git commit -m deploy && git push -f https://github.com/hamoodigan/jackaroo.git gh-pages`. Pages serves within ~1 min; check `curl …/main.dart.js | grep <new string>`.
- APK: `flutter build apk --release` builds clean (no Gradle pins needed, unlike Ludo).
- Sounds are synthesized: `dart run tool/make_sounds.dart` → `assets/sounds/*.wav`.
- Web `shared_preferences` is per origin — a new dev port forgets the saved name/setup.
- Broker is public: anyone with the 4-letter code can read that room's messages. `NetConfig.brokerHost` is one line to swap for a private Mosquitto. Retained lobby/state are cleared when the host quits (`OnlineSession.dispose`).
- 10/Queen random pick happens inside `engine.apply` with `engine.rng`; clients replay then adopt the host snapshot, so different local picks don't matter.
- `test/probe_room_test.dart` prints a room's retained lobby/state: `flutter test test/probe_room_test.dart --dart-define=ROOM=CODE` — handy for online debugging.
- Board photo + detected hole coordinates lived only in the session scratchpad (now gone); the numeric template in `board_geometry.dart` is the source of truth.

## Added after the handoff was first written (same day, 2026-08-25 afternoon)
- Bots/remote players animate 1.7× slower (`GameConfig.botSlow`) and every marble they moved keeps a gold ring (`GameController.lastMoved`) until the next move.
- Base hole = the corner (apex) hole beside the seat's pocket; the home lane branches at rel 74 (`GameConfig.homeBranch`), two holes before the base. Consequences in the engine: `_advances()` returns BOTH the track hole and the home slot when both fit (player chooses), track moves wrap past the base (a marble that misses the lane goes around again). Base hole is tinted + ringed in the seat colour.
- Rejoin: stable `LocalStorage.playerId`, `lastRoom` code, "Rejoin room XXXX" button on the Online screen (`OnlineController.rejoin`): re-reads retained lobby + state; host resumes as authority with `initialState`, guests relaunch from the snapshot. Quitting a game or leaving the lobby forgets the room. Verified only by `test/online_flow_test.dart` "rejoin" (controller level) — the UI flow was NOT exercised live because the user was using the PC.

- Card mechanic (user request): tap a card once → it lifts, every reachable destination pulses in the player's colour (`_TargetMarker`/`_RingPainter` now take a colour) and the path holes are dotted in that colour (`GameController.pathCells` from `engine.pathCells(move)`, drawn by `_PathPainter`). Tap a lit destination to move (marble resolved automatically when unambiguous), or tap the same card again to play it when it has one option / to burn it when nothing is playable. Tapping bare felt cancels (`tapBackground`). Marble-first flows (7 split, Jack swap) still work.
- Full-game check: `test/engine_test.dart` "40 full bot games" plays 40 seeded games with mixed rules and asserts after EVERY move: 4 marbles per seat, no two marbles on one hole, unique home slots, 52 cards accounted for and unique, bot only picks legal moves, game finishes with all 8 team marbles home. Passed first time. No live UI play-through was done for this batch (user was using the PC).

## Current state & next steps
- Done & live: octagon board, all cards incl. new 10/Queen powers + toggles, card guide (home / in-game ? / pause menu), online rooms, EN/AR, PWA + APK, docs, 53 tests.
- Unverified: real phones (only desktop Chrome incl. a narrow window), iOS Safari audio (needs first tap), Arabic RTL layout, landscape, long online sessions.
- Missing online features: host leaving permanently mid-game (guests can only wait / rejoin later), play-again in an online room (buttons hidden), spectators. Rejoin exists but its UI path is untested live.
- Recommended next: (1) test on the user's and cousin's phones; (2) add rejoin (client re-subscribes to `state` retained snapshot with its stored seat/id); (3) optional private broker.
- Working tree clean, all pushed (last commit `5989982`).

## Key files & locations
- `C:\Users\DELL\Desktop\Work\Projects\Jackaroo` — project root; `README.md` architecture/run commands.
- `lib/domain/engine/jackaroo_engine.dart` — all rules, `_advanceTurn`, `CardEffect`; `bot_engine.dart` — AI scoring.
- `lib/domain/entities/rules.dart` — house-rule toggles (jackSwapAny, fiveMovesAny, kingBurnsPath, canBurnPartner, sevenSplit, tenSkip, queenSteal).
- `lib/presentation/controllers/game_controller.dart` — tap flow, special-move button state, online host/client logic.
- `lib/presentation/controllers/online_controller.dart` + `lib/data/net/*` — lobby, RoomService (mqtt), OnlineSession, NetConfig.
- `lib/presentation/widgets/board_geometry.dart` / `board_painter.dart` / `board_view.dart` — octagon board, holes, marbles, centre card.
- `lib/presentation/widgets/hand_view.dart` — cards, status line, power button, effect banner.
- `lib/core/localization/app_translations.dart` — every string EN+AR incl. card guide text.
- `test/` — engine, card_flow, geometry, online_flow, broker_connectivity, probe_room.
- Live: https://hamoodigan.github.io/jackaroo/ · repo https://github.com/hamoodigan/jackaroo · APK `build/app/outputs/flutter-apk/app-release.apk`.
