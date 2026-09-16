/// Shared spacing/radius tokens so new widgets stop hardcoding literals.
/// Existing screens keep their own literals for now — migrate opportunistically
/// when a screen is next touched.
abstract final class KsRadius {
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

abstract final class KsSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}
