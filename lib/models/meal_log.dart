import 'package:track_health/models/meal_type.dart';

class MealLog {
  final String id;
  final String userId;
  final String name;
  final int calories;
  final DateTime timestamp;
  final MealType type;

  MealLog({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map, String id) {
    return MealLog(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      type: MealType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => MealType.snack,
      ),
    );
  }
}
