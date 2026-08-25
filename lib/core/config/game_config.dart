/// Board dimensions and timing knobs. Everything that shapes the game
/// (but is not a *rule*) lives here so it can be tuned in one place.
class GameConfig {
  GameConfig._();

  /// Cells on each side of the square track.
  static const int cellsPerSide = 19;

  /// Total track cells (4 sides).
  static const int trackLength = cellsPerSide * 4;

  /// Index (within its 19-hole segment) of a seat's base/entry hole. The
  /// segment starts AT the base hole on the real board.
  static const int entryOffset = 0;

  /// Cells in each seat's home lane.
  static const int homeSize = 4;

  /// Last track hole (relative) from which a marble can turn into its home
  /// lane: one step past it is home slot 0. On the real board the lane
  /// branches two holes before the base (corner) hole.
  static const int homeBranch = trackLength - 2;

  static const int marblesPerPlayer = 4;
  static const int seats = 4;
  static const int handSize = 4;

  /// Animation / pacing.
  static const Duration marbleStep = Duration(milliseconds: 60);
  static const Duration marbleHop = Duration(milliseconds: 320);
  /// Relaxed-pace bot timings (scaled by the "bot pace" setting).
  static const Duration botThink = Duration(milliseconds: 2200);
  static const Duration botPause = Duration(milliseconds: 1500);

  /// Bots (and remote players) animate this much slower than local taps so
  /// humans can follow what happened.
  static const double botSlow = 2.6;
  static const Duration dealDelay = Duration(milliseconds: 400);
}
