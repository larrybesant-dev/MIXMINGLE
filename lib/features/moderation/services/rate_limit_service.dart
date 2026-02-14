import 'package:shared_preferences/shared_preferences.dart';

class RateLimitService {
  static const String _reportTimestampsKey = 'report_timestamps';
  static const int _maxReportsPerHour = 3;
  static const Duration _rateLimitWindow = Duration(hours: 1);

  /// Checks if the user can submit a report based on rate limits
  ///
  /// Returns true if the user has not exceeded 3 reports in the last hour
  Future<bool> canSubmitReport() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = _getTimestamps(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - _rateLimitWindow.inMilliseconds;

    // Filter timestamps within the rate limit window
    final recentTimestamps = timestamps.where((ts) => ts > windowStart).toList();

    return recentTimestamps.length < _maxReportsPerHour;
  }

  /// Records a report submission timestamp
  ///
  /// Call this after successfully submitting a report
  Future<void> recordReportSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = _getTimestamps(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - _rateLimitWindow.inMilliseconds;

    // Keep only timestamps within the window and add the new one
    final recentTimestamps = timestamps.where((ts) => ts > windowStart).toList();
    recentTimestamps.add(now);

    await prefs.setStringList(
      _reportTimestampsKey,
      recentTimestamps.map((ts) => ts.toString()).toList(),
    );
  }

  /// Gets the number of remaining reports the user can submit this hour
  Future<int> getRemainingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = _getTimestamps(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - _rateLimitWindow.inMilliseconds;

    final recentTimestamps = timestamps.where((ts) => ts > windowStart).toList();
    return (_maxReportsPerHour - recentTimestamps.length).clamp(0, _maxReportsPerHour);
  }

  /// Gets the time until the user can submit another report
  ///
  /// Returns null if the user can already submit a report
  Future<Duration?> getTimeUntilNextReport() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = _getTimestamps(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - _rateLimitWindow.inMilliseconds;

    final recentTimestamps = timestamps.where((ts) => ts > windowStart).toList();

    if (recentTimestamps.length < _maxReportsPerHour) {
      return null;
    }

    // Find the oldest timestamp in the window
    recentTimestamps.sort();
    final oldestTimestamp = recentTimestamps.first;
    final unlockTime = oldestTimestamp + _rateLimitWindow.inMilliseconds;

    return Duration(milliseconds: unlockTime - now);
  }

  List<int> _getTimestamps(SharedPreferences prefs) {
    final timestampStrings = prefs.getStringList(_reportTimestampsKey) ?? [];
    return timestampStrings
        .map((s) => int.tryParse(s))
        .where((ts) => ts != null)
        .cast<int>()
        .toList();
  }
}
