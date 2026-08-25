/// Board dimensions and timing knobs. Everything that shapes the game
/// (but is not a *rule*) lives here so it can be tuned in one place.
class GameConfig {
  GameConfig._();

  /// Cells on each side of the square track.
  static const int cellsPerSide = 19;

  /// Total track cells (4 sides).
  static const int trackLength = cellsPerSide * 4;

  /// Index (within its side) of the cell where a seat's marbles enter.
  static const int entryOffset = 9;

  /// Cells in each seat's home lane.
  static const int homeSize = 4;

  static const int marblesPerPlayer = 4;
  static const int seats = 4;
  static const int handSize = 4;

  /// Animation / pacing.
  static const Duration marbleStep = Duration(milliseconds: 60);
  static const Duration marbleHop = Duration(milliseconds: 320);
  static const Duration botThink = Duration(milliseconds: 900);
  static const Duration dealDelay = Duration(milliseconds: 400);
}
