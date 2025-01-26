import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:track_health/models/meal_log.dart';
import 'package:track_health/theme/app_colors.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final List<Map<String, dynamic>> _groupedMeals = [];
  static const int _limit = 20;
  DateTime? _selectedDate;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMeals();
    }
  }

  Future<void> _loadMeals() async {
    if (_isLoading || (!_hasMore && !_isFiltered)) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('meal_logs')
          .where('userId', isEqualTo: _userId);

      if (_selectedDate != null) {
        // Create start and end of day in local timezone
        final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month,
            _selectedDate!.day, 0, 0, 0);
        final endOfDay = DateTime(_selectedDate!.year, _selectedDate!.month,
            _selectedDate!.day, 23, 59, 59, 999);

        print(
            'Filtering meals between: ${startOfDay.toIso8601String()} and ${endOfDay.toIso8601String()}');

        query = query
            .where('timestamp',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('timestamp',
                isLessThan:
                    endOfDay.add(const Duration(seconds: 1)).toIso8601String());
      }

      query = query.orderBy('timestamp', descending: true);

      if (!_isFiltered) {
        query = query.limit(_limit);
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }
      }

      final QuerySnapshot snapshot = await query.get();
      print('Found ${snapshot.docs.length} meals');

      if (_isFiltered) {
        _groupedMeals.clear();
        _lastDocument = null;
        _hasMore = true;
        _isFiltered = false;
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;
      _processMeals(snapshot.docs);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meals: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _processMeals(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final meal = MealLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final date = DateFormat('yyyy-MM-dd').format(meal.timestamp);

      final existingGroupIndex =
          _groupedMeals.indexWhere((g) => g['date'] == date);

      if (existingGroupIndex == -1) {
        _groupedMeals.add({
          'date': date,
          'meals': <MealLog>[meal],
          'totalCalories': meal.calories,
        });
      } else {
        final group = _groupedMeals[existingGroupIndex];
        final meals = group['meals'] as List<MealLog>;

        // Check for duplicates
        if (!meals.any((m) => m.id == meal.id)) {
          meals.add(meal);
          group['totalCalories'] =
              (group['totalCalories'] as int) + meal.calories;
        }
      }
    }

    // Sort meals within each group by timestamp
    for (var group in _groupedMeals) {
      final meals = group['meals'] as List<MealLog>;
      meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _refreshMeals() async {
    _lastDocument = null;
    _hasMore = true;
    _groupedMeals.clear();
    await _loadMeals();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isFiltered = true;
      });
      await _refreshMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshMeals,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Meal History'),
            actions: [
              IconButton(
                tooltip: 'Select Date',
                icon: Icon(
                  _selectedDate != null
                      ? Icons.calendar_today
                      : Icons.calendar_month,
                  color:
                      _selectedDate != null ? theme.colorScheme.primary : null,
                ),
                onPressed: () => _selectDate(context),
              ),
              if (_selectedDate != null)
                IconButton(
                  tooltip: 'Clear Filter',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _isFiltered = true;
                      _hasMore = true;
                    });
                    _refreshMeals();
                  },
                ),
            ],
          ),
          if (_selectedDate != null)
            SliverToBoxAdapter(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Showing meals for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_groupedMeals.isEmpty && !_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Text('No meal history found'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _groupedMeals.length) {
                      if (_isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return null;
                    }

                    return _buildDayGroup(_groupedMeals[index]);
                  },
                  childCount: _groupedMeals.length + (_isLoading ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayGroup(Map<String, dynamic> group) {
    final date = DateTime.parse(group['date']);
    final meals = group['meals'] as List<MealLog>;
    final totalCalories = group['totalCalories'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(date),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCalories kcal',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        ...meals.map((meal) => _MealCard(meal: meal)),
        const Divider(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _MealCard extends StatelessWidget {
  final MealLog meal;

  const _MealCard({
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Text(
              meal.type.displayName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
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
    );
  }
}
