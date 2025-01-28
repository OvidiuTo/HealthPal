
class ActivityLog {
  final String id;
  final String userId;
  final String name;
  final int minutes;
  final int caloriesBurned;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.name,
    required this.minutes,
    required this.caloriesBurned,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'minutes': minutes,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ActivityLog fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      userId: map['userId'],
      name: map['name'],
      minutes: map['minutes'],
      caloriesBurned: map['caloriesBurned'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
