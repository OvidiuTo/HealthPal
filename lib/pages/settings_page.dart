import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_health/blocs/auth/auth_bloc.dart';
import 'package:track_health/models/user_model.dart';
import 'package:track_health/blocs/theme/theme_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _calorieGoalController = TextEditingController();

  @override
  void dispose() {
    _calorieGoalController.dispose();
    super.dispose();
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
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const Center(child: Text('No user data found'));
                }

                final user = UserModel.fromMap(userData);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Calorie Goal',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${user.dailyCalorieGoal} calories',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showUpdateCalorieGoalDialog(
                                    context,
                                    state.user.uid,
                                    user.dailyCalorieGoal,
                                  ),
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dark Mode',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                BlocBuilder<ThemeBloc, ThemeState>(
                                  builder: (context, state) {
                                    return Switch(
                                      value: state.isDarkMode,
                                      onChanged: (_) {
                                        context
                                            .read<ThemeBloc>()
                                            .add(ToggleTheme());
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text('Sign Out'),
                        leading: const Icon(Icons.logout),
                        onTap: () {
                          context.read<AuthBloc>().add(SignOutRequested());
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showUpdateCalorieGoalDialog(
      BuildContext context, String userId, int currentGoal) {
    _calorieGoalController.text = currentGoal.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Calorie Goal'),
        content: TextField(
          controller: _calorieGoalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Calorie Goal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newGoal = int.parse(_calorieGoalController.text);
                if (newGoal <= 0) {
                  throw const FormatException('Invalid calorie goal');
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'dailyCalorieGoal': newGoal});

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calorie goal updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
