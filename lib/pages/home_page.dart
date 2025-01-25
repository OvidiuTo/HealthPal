import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_health/blocs/auth/auth_bloc.dart';
import 'package:track_health/models/user_model.dart';
import 'package:track_health/models/meal_log.dart';
import 'package:intl/intl.dart';
import 'package:track_health/theme/app_colors.dart';
import 'package:track_health/models/meal_type.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  MealType _selectedMealType = MealType.snack;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _showAddMealDialog(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Meal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color:
                            isDark ? AppColors.textLight : AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<MealType>(
                value: _selectedMealType,
                decoration: InputDecoration(
                  labelText: 'Meal Type',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.textLight.withOpacity(0.7) : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.restaurant_menu,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
                dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                items: MealType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (MealType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedMealType = newValue);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Meal Name',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.textLight.withOpacity(0.7) : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.restaurant_menu,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories',
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.textLight.withOpacity(0.7) : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.local_fire_department,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _addMeal(context, userId),
                  child: const Text('Add Meal'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMeal(BuildContext context, String userId) async {
    if (_nameController.text.isEmpty) {
      _showError(context, 'Please enter a meal name');
      return;
    }

    if (_caloriesController.text.isEmpty) {
      _showError(context, 'Please enter calories');
      return;
    }

    try {
      final calories = int.parse(_caloriesController.text);
      if (calories <= 0) {
        _showError(context, 'Please enter a valid calorie amount');
        return;
      }

      final mealLog = MealLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: _nameController.text.trim(),
        calories: calories,
        timestamp: DateTime.now(),
        type: _selectedMealType,
      );

      await FirebaseFirestore.instance
          .collection('meal_logs')
          .doc(mealLog.id)
          .set(mealLog.toMap());

      if (mounted) {
        Navigator.pop(context);
        _nameController.clear();
        _caloriesController.clear();
        _showSuccess(context, 'Meal added successfully');
      }
    } catch (e) {
      _showError(context, 'Error adding meal: ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();

        return Scaffold(
          body: SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(state.user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const Center(child: Text('No user data found'));
                }

                final user = UserModel.fromMap(userData);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('meal_logs')
                      .where('userId', isEqualTo: state.user.uid)
                      .where('timestamp',
                          isGreaterThanOrEqualTo: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ).toIso8601String())
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, mealSnapshot) {
                    int todayCalories = 0;
                    final meals = <MealLog>[];

                    if (mealSnapshot.hasData) {
                      for (var doc in mealSnapshot.data!.docs) {
                        final meal = MealLog.fromMap(
                            doc.data() as Map<String, dynamic>, doc.id);
                        todayCalories += meal.calories;
                        meals.add(meal);
                      }
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Health Tracker'),
                              Text(
                                state.user.email ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _CalorieCard(
                              todayCalories: todayCalories,
                              goalCalories: user.dailyCalorieGoal,
                              onAddMeal: () =>
                                  _showAddMealDialog(context, state.user.uid),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Today's Meals",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Meal'),
                                  onPressed: () => _showAddMealDialog(
                                      context, state.user.uid),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: meals.isEmpty
                              ? const SliverToBoxAdapter(
                                  child: Center(
                                    child: Text('No meals logged today'),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _MealCard(
                                      meal: meals[index],
                                      onDelete: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('meal_logs')
                                              .doc(meals[index].id)
                                              .delete();
                                          _showSuccess(context,
                                              'Meal deleted successfully');
                                        } catch (e) {
                                          _showError(context,
                                              'Error deleting meal: ${e.toString()}');
                                        }
                                      },
                                    ),
                                    childCount: meals.length,
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMealDialog(context, state.user.uid),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final int todayCalories;
  final int goalCalories;
  final VoidCallback onAddMeal;

  const _CalorieCard({
    required this.todayCalories,
    required this.goalCalories,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = todayCalories / goalCalories;
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = progress >= 1
        ? Colors.red
        : progress >= 0.8
            ? Colors.orange
            : colorScheme.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: '$todayCalories',
                            style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' / $goalCalories',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddMeal,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealLog meal;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            meal.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.type.displayName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  )),
              Text(DateFormat('HH:mm').format(meal.timestamp)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${meal.calories} cal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
