/// 2D boolean mask representing a silhouette shape.
class ShapeMask {
  final String name;
  final int width;
  final int height;
  final List<List<bool>> grid;

  const ShapeMask({
    required this.name,
    required this.width,
    required this.height,
    required this.grid,
  });

  /// Total number of active pixels in the mask.
  int get activeCellCount {
    int count = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (grid[y][x]) count++;
      }
    }
    return count;
  }

  bool isSet(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return grid[y][x];
  }

  /// Parses an ASCII multiline string where '#' or '*' is ON, and '.' or ' ' is OFF.
  factory ShapeMask.fromAscii(String name, String ascii) {
    final lines = ascii
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
    final h = lines.length;
    int maxW = 0;
    for (final l in lines) {
      if (l.length > maxW) maxW = l.length;
    }

    final grid = List.generate(h, (y) {
      final line = lines[y];
      return List.generate(maxW, (x) {
        if (x >= line.length) return false;
        final c = line[x];
        return c == '#' || c == '*' || c == 'O' || c == '1';
      });
    });

    return ShapeMask(name: name, width: maxW, height: h, grid: grid);
  }

  /// Resamples the mask onto a target [targetW] x [targetH] grid with smoothing.
  ShapeMask resample(int targetW, int targetH) {
    if (width == targetW && height == targetH) return this;

    final newGrid = List.generate(targetH, (ty) {
      return List.generate(targetW, (tx) {
        // Nearest or box-sampling
        final sx = (tx / targetW * width).floor().clamp(0, width - 1);
        final sy = (ty / targetH * height).floor().clamp(0, height - 1);
        return grid[sy][sx];
      });
    });

    return ShapeMask(name: name, width: targetW, height: targetH, grid: newGrid);
  }
}
