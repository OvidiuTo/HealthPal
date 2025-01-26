import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_health/blocs/auth/auth_bloc.dart';
import 'package:track_health/models/user_model.dart';
import 'package:track_health/models/meal_log.dart';
import 'package:intl/intl.dart';
import 'package:track_health/theme/app_colors.dart';
import 'package:track_health/models/meal_type.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:track_health/pages/history_page.dart';
import 'package:track_health/models/activity_log.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _activityNameController = TextEditingController();
  final _activityMinutesController = TextEditingController();
  final _activityCaloriesController = TextEditingController();
  MealType _selectedMealType = MealType.snack;
  final _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _currentField = '';
  int _currentIndex = 0;
  int _selectedTab = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pageController = PageController(initialPage: _selectedTab);
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('🎤 Speech recognition error: $error');
          _resetState();
        },
        onStatus: (status) {
          print('🎤 Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _resetState();
          }
        },
      );
      print('🎤 Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      print('❌ Error initializing speech: $e');
      _speechEnabled = false;
    }
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentField = '';
      });
      print(
          '🎤 State reset - isListening: $_isListening, currentField: $_currentField');
    }
  }

  Future<void> _startListening(String field) async {
    print('🎤 Start listening - Current states:'
        '\n   isListening: ${_speechToText.isListening}'
        '\n   _currentField: $_currentField'
        '\n   field: $field');
    if (!_speechEnabled) {
      print('❌ Speech recognition not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    try {
      setState(() {
        _currentField = field;
        _isListening = true;
      });
      print('🎤 After setState in start:'
          '\n   isListening: ${_speechToText.isListening}'
          '\n   _currentField: $_currentField');

      await _speechToText.listen(
        onResult: (result) => _onSpeechResult(result, field),
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() {});
            print('🎤 Sound level change:'
                '\n   isListening: ${_speechToText.isListening}'
                '\n   _currentField: $_currentField');
          }
        },
        listenFor: const Duration(seconds: 30),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
      print(
          '🎤 Listen method completed - isListening: ${_speechToText.isListening}');
    } catch (e) {
      print('❌ Error in start listening:'
          '\n   Error: $e'
          '\n   isListening: ${_speechToText.isListening}'
          '\n   _currentField: $_currentField');
      setState(() {
        _isListening = false;
        _currentField = '';
      });
    }
  }

  Future<void> _stopListening() async {
    print('🎤 Stopping speech');
    try {
      await _speechToText.stop();
      _resetState();
    } catch (e) {
      print('❌ Error stopping speech recognition: $e');
      _resetState();
    }
  }

  void _onSpeechResult(result, String field) {
    print('🎤 Speech result - Current states:'
        '\n   isListening: ${_speechToText.isListening}'
        '\n   _currentField: $_currentField'
        '\n   field: $field');

    final text = result.recognizedWords;
    print('🎤 Recognized words for $field: $text');

    if (field == 'name') {
      setState(() => _nameController.text = text);
    } else if (field == 'calories') {
      final numericRegex = RegExp(r'\d+');
      final match = numericRegex.firstMatch(text);
      if (match != null) {
        setState(() => _caloriesController.text = match.group(0)!);
      }
    }

    // If this is the final result, just reset the state
    if (result.finalResult) {
      print('🎤 Final result received');
      _resetState();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required String field,
    required VoidCallback onStateChange,
    TextInputType? keyboardType,
  }) {
    final isListeningThisField = _isListening && _currentField == field;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isDark ? AppColors.textLight.withOpacity(0.7) : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            keyboardType: keyboardType,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            if (_isListening) {
              await _stopListening();
            } else {
              await _startListening(field);
            }
            onStateChange();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListeningThisField
                  ? AppColors.darkPrimary.withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isListeningThisField ? Icons.mic : Icons.mic_none,
                  color: isListeningThisField
                      ? Colors.red
                      : (isDark ? AppColors.textLight : AppColors.textDark),
                  size: isListeningThisField ? 24 : 20,
                ),
                if (isListeningThisField)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeField(bool isDark, StateSetter setModalState) {
    return DropdownButtonFormField<MealType>(
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
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.category,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
      style: TextStyle(
        color: isDark ? AppColors.textLight : AppColors.textDark,
      ),
      dropdownColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      items: MealType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (MealType? newValue) {
        if (newValue != null) {
          setModalState(() => _selectedMealType = newValue);
        }
      },
    );
  }

  void _showAddMealDialog(BuildContext context, String userId) {
    // Reset values when opening the modal
    _nameController.clear();
    _caloriesController.clear();
    _selectedMealType = MealType.snack;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Meal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Meal Name',
                icon: Icons.restaurant_menu,
                isDark: isDark,
                field: 'name',
                onStateChange: () => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              _buildMealTypeField(isDark, setModalState),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _caloriesController,
                label: 'Calories',
                icon: Icons.local_fire_department,
                isDark: isDark,
                field: 'calories',
                keyboardType: TextInputType.number,
                onStateChange: () => setModalState(() {}),
              ),
              const SizedBox(height: 20),
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
    ).whenComplete(() {
      // Reset values when closing the modal
      _nameController.clear();
      _caloriesController.clear();
      _selectedMealType = MealType.snack;
      // Also reset speech recognition state if it's active
      if (_isListening) {
        _stopListening();
      }
    });
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

  void _showAddActivityDialog(BuildContext context) {
    _activityNameController.clear();
    _activityMinutesController.clear();
    _activityCaloriesController.clear();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _activityNameController,
              decoration: InputDecoration(
                labelText: 'Activity Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.fitness_center),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activityMinutesController,
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _activityCaloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories Burned',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _addActivity(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Activity'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addActivity(BuildContext context) async {
    if (_activityNameController.text.isEmpty ||
        _activityMinutesController.text.isEmpty ||
        _activityCaloriesController.text.isEmpty) {
      _showError(context, 'Please fill in all fields');
      return;
    }

    try {
      final minutes = int.parse(_activityMinutesController.text);
      final calories = int.parse(_activityCaloriesController.text);

      if (minutes <= 0 || calories <= 0) {
        _showError(context, 'Please enter valid numbers');
        return;
      }

      final now = DateTime.now();
      final timestamp = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ).toIso8601String();

      final activityData = {
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'name': _activityNameController.text.trim(),
        'minutes': minutes,
        'caloriesBurned': calories,
        'timestamp': timestamp,
      };

      print('Adding activity: $activityData');

      await FirebaseFirestore.instance
          .collection('activity_logs')
          .add(activityData);

      if (mounted) {
        Navigator.pop(context);
        _showSuccess(context, 'Activity added successfully');
      }
    } catch (e) {
      print('Error adding activity: $e');
      _showError(context, 'Error adding activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();

        return Scaffold(
          body: StreamBuilder<DocumentSnapshot>(
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

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activity_logs')
                        .where('userId', isEqualTo: state.user.uid)
                        .where('timestamp',
                            isGreaterThanOrEqualTo: DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ).toIso8601String())
                        .where('timestamp',
                            isLessThan: DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day + 1,
                            ).toIso8601String())
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, activitySnapshot) {
                      int todayMinutes = 0;
                      int todayCaloriesBurned = 0;
                      final activities = <ActivityLog>[];

                      if (activitySnapshot.hasError) {
                        print(
                            'Activity snapshot error: ${activitySnapshot.error}');
                      }

                      if (activitySnapshot.hasData) {
                        print(
                            'Found ${activitySnapshot.data!.docs.length} activities');
                        for (var doc in activitySnapshot.data!.docs) {
                          final activity = ActivityLog.fromMap(
                              doc.data() as Map<String, dynamic>, doc.id);
                          print(
                              'Activity: ${activity.name}, Minutes: ${activity.minutes}, Calories: ${activity.caloriesBurned}');
                          todayMinutes += activity.minutes;
                          todayCaloriesBurned += activity.caloriesBurned;
                          activities.add(activity);
                        }
                        print(
                            'Total minutes: $todayMinutes, Total calories burned: $todayCaloriesBurned');
                      }

                      return CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            floating: true,
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Health Tracker'),
                                // Text(
                                //   state.user.email ?? '',
                                //   style: Theme.of(context)
                                //       .textTheme
                                //       .bodySmall
                                //       ?.copyWith(color: Colors.white70),
                                // ),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _CalorieCard(
                                    todayCalories: todayCalories,
                                    goalCalories: user.dailyCalorieGoal,
                                    onAddMeal: () => _showAddMealDialog(
                                        context, state.user.uid),
                                  ),
                                  const SizedBox(height: 16),
                                  _ActivityCard(
                                    todayMinutes: todayMinutes,
                                    todayCaloriesBurned: todayCaloriesBurned,
                                    onAddActivity: () =>
                                        _showAddActivityDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Today's Log",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      TextButton.icon(
                                        icon: Icon(_selectedTab == 0
                                            ? Icons.restaurant
                                            : Icons.fitness_center),
                                        label: Text(_selectedTab == 0
                                            ? 'Add Meal'
                                            : 'Add Activity'),
                                        onPressed: () => _selectedTab == 0
                                            ? _showAddMealDialog(
                                                context, state.user.uid)
                                            : _showAddActivityDialog(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _selectedTab == 0
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.restaurant,
                                                  size: 20,
                                                  color: _selectedTab == 0
                                                      ? Colors.white
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Meals',
                                                  style: TextStyle(
                                                    color: _selectedTab == 0
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _pageController.animateToPage(
                                              1,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _selectedTab == 1
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.fitness_center,
                                                  size: 20,
                                                  color: _selectedTab == 1
                                                      ? Colors.white
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Activities',
                                                  style: TextStyle(
                                                    color: _selectedTab == 1
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 400,
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _selectedTab = index;
                                      });
                                    },
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: meals.isEmpty
                                            ? const Center(
                                                child: Text(
                                                    'No meals logged today'))
                                            : ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: meals.length,
                                                itemBuilder: (context, index) =>
                                                    _MealCard(
                                                  meal: meals[index],
                                                  onDelete: () async {
                                                    try {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'meal_logs')
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
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: _ActivityList(
                                          activities: activities,
                                          onDelete: (id) async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('activity_logs')
                                                  .doc(id)
                                                  .delete();
                                              _showSuccess(context,
                                                  'Activity deleted successfully');
                                            } catch (e) {
                                              _showError(context,
                                                  'Error deleting activity: ${e.toString()}');
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'activity',
                onPressed: () => _showAddActivityDialog(context),
                child: const Icon(Icons.fitness_center),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'meal',
                onPressed: () => _showAddMealDialog(context, state.user.uid),
                child: const Icon(Icons.restaurant),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _nameController.dispose();
    _caloriesController.dispose();
    _activityNameController.dispose();
    _activityMinutesController.dispose();
    _activityCaloriesController.dispose();
    _pageController.dispose();
    super.dispose();
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

class _ActivityCard extends StatelessWidget {
  final int todayMinutes;
  final int todayCaloriesBurned;
  final VoidCallback onAddActivity;

  const _ActivityCard({
    required this.todayMinutes,
    required this.todayCaloriesBurned,
    required this.onAddActivity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      'Today\'s Activities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$todayMinutes min',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$todayCaloriesBurned kcal',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddActivity,
                  color: colorScheme.primary,
                ),
              ],
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
              '${meal.calories} kcal',
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

class _ActivityList extends StatelessWidget {
  final List<ActivityLog> activities;
  final Function(String) onDelete;

  const _ActivityList({
    required this.activities,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return activities.isEmpty
        ? const Center(child: Text('No activities logged today'))
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Dismissible(
                key: Key(activity.id),
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
                onDismissed: (_) => onDelete(activity.id),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      activity.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activity.minutes} minutes',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(DateFormat('HH:mm').format(activity.timestamp)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activity.caloriesBurned} kcal',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}
