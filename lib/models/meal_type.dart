enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };
}
