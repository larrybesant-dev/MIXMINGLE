class SpeedDatingRound {
  final String roundId;
  final List<String> participants;
  final DateTime startTime;
  final DateTime? endTime;
  SpeedDatingRound({required this.roundId, required this.participants, required this.startTime, this.endTime});
}
