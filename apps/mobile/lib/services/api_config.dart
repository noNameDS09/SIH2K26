/// Central FastAPI base URL for the app.
///
/// Override at build/run time with:
///   flutter run --dart-define=KS_API_BASE=http://10.0.2.2:8000
///
/// Default targets the Android emulator's host-loopback address so a local
/// `uvicorn` on the dev machine is reachable without any build-file change.
abstract final class ApiConfig {
  static const String base = String.fromEnvironment(
    'KS_API_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
