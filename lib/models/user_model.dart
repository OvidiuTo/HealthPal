class UserModel {
  final String uid;
  final String email;
  final int dailyCalorieGoal;

  UserModel({
    required this.uid,
    required this.email,
    this.dailyCalorieGoal = 2000,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'dailyCalorieGoal': dailyCalorieGoal,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      dailyCalorieGoal: map['dailyCalorieGoal'] ?? 2000,
    );
  }
}
