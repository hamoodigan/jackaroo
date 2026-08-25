# Session Handoff — 2026-08-25 (Jackaroo v1.1: real board + online play)

## TL;DR
Complete Flutter Jackaroo built in one session and iterated live with the user.
- Web (installable PWA, iPhone + Android): **https://hamoodigan.github.io/jackaroo/**
- GitHub `hamoodigan/jackaroo` — source on `main`, web build on `gh-pages`.
- Android APK: `build/app/outputs/flutter-apk/app-release.apk` (~51 MB).
- Online multiplayer works out of the box over the free public HiveMQ MQTT
  broker (no account, no server): Play online → Create room → share 4-letter
  code → friends Join → host presses Start. Verified end-to-end in two browser
  windows against the real broker (host move → guest, guest intent → host,
  bots run on host, both boards identical).
- Board = the real octagonal Jackaroo board, traced from a product photo.
- 48 tests green: engine rules, every card through the real tap flow,
  geometry, host/client protocol (in-memory broker), live broker round-trip.

## Board geometry (traced from the photo the user supplied)
`lib/presentation/widgets/board_geometry.dart`, unit = hole pitch `p`.
Octagon (apothem 11.9p). The track (76 holes) is a loop with 8 apexes:
4 straight diagonal edges of 5 holes and 4 dented orthogonal sides
(5 holes diagonally in, 6 straight at y = -5.33p, 5 diagonally out).
Per seat (19 holes, relative index from the base hole, `entryOffset = 0`):
base hole = 4th hole of the seat's diagonal edge (rel 0), apex (1), 4 in (2-5),
6 straight (6-11), 4 out (12-15), apex (16), 2 along the next edge (17-18).
Home lane: 4 holes from the threshold hole (rel -1) along the corner diagonal
toward the centre. Waiting pocket: diamond of 4 holes in the notch of the
next orthogonal side, centre (-2.4p, -7.9p) for the top-left template, pulled
toward the seat's base hole. Seats: 0 bottom-right corner, 1 bottom-left,
2 top-left, 3 top-right (template rotated 180/270/0/90 deg). Clockwise travel.
Centre: cream octagon (3.3p) showing the last played card, like the deck on
the real board. Hole photo + blob coordinates live in the session scratchpad
only; the numbers above are all you need.

Earlier attempts the user rejected: square ring (CCW), then a plus/cross with
arms. If the user says "the shape is wrong" again, ask for a photo first.

## Online protocol (lib/data/net + game_controller online mode)
- Broker: `broker.hivemq.com` (tcp 1883 on Android/iOS, wss 8884 `/mqtt` on web).
  `NetConfig` holds host/ports/topic root `jackaroo-hg/v1/<CODE>`.
- Topics: `lobby` (retained, host), `join`/`leave` (clients), `state`
  (retained snapshot `{seq,state}`, host), `moves` (host → all
  `{seq,move,state}`), `intent` (client → host `{seq,move}`).
- Host is authoritative: validates intents against `engine.legalMoves`, applies,
  broadcasts; clients replay the move for animation then adopt the snapshot.
  Bots run on the host only. Empty seats become bots at Start.
- `GameController(online: OnlineSession)`; `viewSeat` = my seat online;
  `isLocalSeat()` gates taps; clients only ever see their own hand.
- Not yet: reconnect/rejoin after refresh, host leaving mid-game, play-again
  online (buttons hidden), spectators. Retained lobby/state are cleared when
  the host quits (OnlineSession.dispose).

## Gotchas (do not repeat)
- **GetX SmartManagement disposed the GameController** when the lobby route was
  replaced with `Get.offNamed('/game')` — widgets kept a stale reference and
  `_run` silently bailed on `_disposed`, so the host never published. Fix:
  `Get.put(..., permanent: true)` (both online launch and offline setup).
- Git Bash heredocs with unicode/quotes in Dart broke twice — write Dart with
  the Write tool or a python script file, not inline heredocs.
- `Obx` must read an observable (Get.locale is not one).
- Chrome caches the dev bundle: hard refresh (Ctrl+Shift+R) before debugging.
- `flutter build web --base-href /jackaroo/` needs `MSYS_NO_PATHCONV=1` in Git Bash.
- No global git identity on this PC: repo-local user.name/email are set in the
  project repo AND must be set again in the throwaway `build/web` repo.
- Public broker = anyone with the code can read the room. Fine for family play;
  move `NetConfig.brokerHost` to your own Mosquitto if that matters.
- shared_preferences on web is per origin: a new dev port forgets the name.

## Not yet verified
- Real phones (only Chrome desktop + narrow window were exercised). Sound on
  iOS Safari needs a first tap.
- Arabic RTL layout, landscape.
- Long online sessions (broker keep-alive 30s; no auto-reconnect UI).

## Redeploy
```
MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/jackaroo/"
cd build/web && git init && git config user.email ... && git config user.name ...
git checkout -b gh-pages && git add -A && git commit -m deploy
git push -f https://github.com/hamoodigan/jackaroo.git gh-pages
flutter build apk --release
```

## Key files
- `lib/domain/engine/jackaroo_engine.dart` — all rules; `bot_engine.dart` — AI
- `lib/presentation/controllers/game_controller.dart` — tap flow + online mode
- `lib/presentation/controllers/online_controller.dart` — lobby create/join/start
- `lib/data/net/*` — RoomService (mqtt_client), OnlineSession, NetConfig
- `lib/presentation/widgets/board_geometry.dart` / `board_painter.dart`
- `lib/presentation/screens/cards_screen.dart` — card guide (home, in-game ? icon, pause menu)
- `test/` — engine, card_flow, geometry, online_flow, broker_connectivity, probe_room
