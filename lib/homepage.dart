import 'package:flutter/material.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All diaries
  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _goals = [];

  bool _isLoading = true;
  String _currentView = 'list';
  DateTime _calendarMonth = DateTime.now();

  // This function is used to fetch all diary data from the database
  void _refreshDiaries() async {
    try {
      final data = await SQLHelper.getDiaries();
      if (mounted) {
        setState(() {
          _diaries = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading diaries: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshDiaries(); // Loading the diary when the app starts
    _refreshGoals();
  }

  @override
  void dispose() {
    _feelingController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  void _refreshGoals() async {
    try {
      final data = await SQLHelper.getGoals();
      if (mounted) {
        setState(() {
          _goals = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  Future<void> _addGoal() async {
    final text = _goalController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal first.')),
      );
      return;
    }

    await SQLHelper.createGoal(text);
    _goalController.clear();
    _refreshGoals();
  }

  Future<void> _toggleGoal(int id, bool completed) async {
    await SQLHelper.updateGoal(id, completed: completed);
    _refreshGoals();
  }

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update a diary
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new diary
      // id != null -> update an existing diary
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
    } else {
      _feelingController.clear();
      _descriptionController.clear();
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _feelingController,
                      decoration: const InputDecoration(
                        hintText: 'Feeling',
                        labelText: 'Emotion',
                        suffixIcon: Icon(Icons.emoji_emotions),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe your emotion',
                        labelText: 'Describe emotion',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final feeling = _feelingController.text.trim();
                        final description = _descriptionController.text.trim();

                        if (feeling.isEmpty || description.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please enter both emotion and description.'),
                            ),
                          );
                          return;
                        }

                        try {
                          if (id == null) {
                            final insertedId = await _addDiary();
                            if (insertedId > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Diary entry saved successfully.'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Unable to save the diary entry.'),
                                ),
                              );
                              return;
                            }
                          } else {
                            final updated = await _updateDiary(id);
                            if (updated > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Diary entry updated successfully.'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Unable to update the diary entry.'),
                                ),
                              );
                              return;
                            }
                          }
                        } catch (e) {
                          debugPrint('Error saving diary: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving diary: $e'),
                            ),
                          );
                          return;
                        }

                        // Clear the text fields
                        _feelingController.clear();
                        _descriptionController.clear();

                        // Close the bottom sheet
                        Navigator.of(context).pop();
                      },
                      child: Text(id == null ? 'Create New' : 'Update'),
                    )
                  ],
                ),
              ),
            ));
  }

// Insert a new diary to the database
  Future<int> _addDiary() async {
    final id = await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    _refreshDiaries();
    return id;
  }

  // Update an existing diary
  Future<int> _updateDiary(int id) async {
    final result = await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text);
    _refreshDiaries();
    return result;
  }

  // Delete an item
  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a diary!'),
    ));
    _refreshDiaries();
  }

  DateTime? _parseDiaryDate(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return null;
    return DateTime.tryParse(createdAt);
  }

  String _formatDiaryDay(String? createdAt) {
    final parsed = _parseDiaryDate(createdAt);
    if (parsed == null) return '';
    return parsed.day.toString().padLeft(2, '0');
  }

  String _formatDiaryMonth(String? createdAt) {
    final parsed = _parseDiaryDate(createdAt);
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[parsed.month - 1];
  }

  String _formatDiaryTime(String? createdAt) {
    final parsed = _parseDiaryDate(createdAt);
    if (parsed == null) return createdAt ?? '';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Set<String> _diaryDateKeys() {
    return _diaries
        .map((entry) {
          final createdAt = _parseDiaryDate(entry['createdAt'] as String?);
          if (createdAt == null) return null;
          return DateTime(createdAt.year, createdAt.month, createdAt.day)
              .toIso8601String();
        })
        .whereType<String>()
        .toSet();
  }

  List<Map<String, dynamic>> _diariesForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _diaries.where((entry) {
      final createdAt = _parseDiaryDate(entry['createdAt'] as String?);
      return createdAt != null &&
          createdAt.year == target.year &&
          createdAt.month == target.month &&
          createdAt.day == target.day;
    }).toList();
  }

  void _showEntriesForDate(DateTime date) {
    final entries = _diariesForDate(date);
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries for this day.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final sortedEntries = List<Map<String, dynamic>>.from(entries)
          ..sort((a, b) {
            final first = _parseDiaryDate(a['createdAt'] as String?);
            final second = _parseDiaryDate(b['createdAt'] as String?);
            if (first == null || second == null) return 0;
            return first.compareTo(second);
          });

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (sheetContext, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.day} ${_monthName(date.month)} ${date.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: sortedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = sortedEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                                entry['feeling'] as String? ?? 'No emotion'),
                            subtitle:
                                Text(entry['description'] as String? ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showForm(entry['id'] as int);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarView() {
    final dateKeys = _diaryDateKeys();
    final firstDayOfMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final leadingEmptyDays = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: Colors.pink[50],
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _calendarMonth =
                      DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                }),
              ),
              Expanded(
                child: Text(
                  '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _calendarMonth =
                      DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            physics: const NeverScrollableScrollPhysics(),
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((label) => Center(child: Text(label)))
                .toList(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: [
                ...List.generate(leadingEmptyDays, (_) => const SizedBox()),
                ...List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final date =
                      DateTime(_calendarMonth.year, _calendarMonth.month, day);
                  final hasEntries = dateKeys.contains(
                    DateTime(date.year, date.month, date.day).toIso8601String(),
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showEntriesForDate(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasEntries ? Colors.pink[100] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            day.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: hasEntries
                                  ? Colors.pink[800]
                                  : Colors.black87,
                            ),
                          ),
                          if (hasEntries)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistView() {
    final completedGoals =
        _goals.where((goal) => goal['completed'] == 1).length;
    final totalGoals = _goals.length;
    final progressValue = totalGoals == 0 ? 0.0 : completedGoals / totalGoals;
    final progressPercent = (progressValue * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.pink[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.pink),
                      const SizedBox(width: 8),
                      const Text(
                        'Daily goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('$completedGoals of $totalGoals completed'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.pink[100],
                    color: Colors.pink,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _goalController,
                  decoration: const InputDecoration(
                    hintText: 'Add a daily goal',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addGoal,
                child: const Text('Add Goal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _goals.isEmpty
                ? const Center(
                    child: Text('No goals yet. Add one to get started.'),
                  )
                : ListView.separated(
                    itemCount: _goals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final completed = goal['completed'] == 1;
                      return Card(
                        child: CheckboxListTile(
                          value: completed,
                          title: Text(goal['text'] as String? ?? ''),
                          onChanged: (value) => _toggleGoal(
                            goal['id'] as int,
                            value ?? false,
                          ),
                          secondary: const Icon(Icons.check_circle_outline),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: Container(
        color: Colors.pink[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pink[200],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    'MyDiary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Personal journal app',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.pink),
              title: const Text('Calendar View'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentView = 'calendar';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist, color: Colors.pink),
              title: const Text('Checklist / Daily Goals'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentView = 'checklist';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export, color: Colors.pink),
              title: const Text('Export & Import'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Export & Import screen not implemented yet.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.pink),
              title: const Text('Share App'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Share App screen not implemented yet.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.pink),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Settings screen not implemented yet.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(),
      appBar: AppBar(
        title: const Text("My Diary"),
        actions: [
          if (_currentView == 'calendar')
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => setState(() {
                _currentView = 'list';
              }),
            ),
          if (_currentView == 'checklist')
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => setState(() {
                _currentView = 'list';
              }),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _currentView == 'calendar'
              ? _buildCalendarView()
              : _currentView == 'checklist'
                  ? _buildChecklistView()
                  : Column(
                      children: [
                        Expanded(
                          child: _diaries.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No diary entries yet. Tap + to add one.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 12),
                                  itemCount: _diaries.length,
                                  itemBuilder: (context, index) {
                                    final diary = _diaries[index];
                                    final feeling =
                                        diary['feeling'] as String? ?? '';
                                    final description =
                                        diary['description'] as String? ?? '';
                                    final createdAt =
                                        diary['createdAt'] as String?;
                                    final displayEmoji = feeling.isNotEmpty &&
                                            RegExp(
                                              r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}]',
                                              unicode: true,
                                            ).hasMatch(feeling)
                                        ? feeling
                                        : '😊';

                                    return Card(
                                      color: Colors.pink[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        _formatDiaryDay(
                                                            createdAt),
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatDiaryMonth(
                                                            createdAt),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        feeling,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        description,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor:
                                                      Colors.pink[100],
                                                  child: Text(
                                                    displayEmoji,
                                                    style: const TextStyle(
                                                        fontSize: 20),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDiaryTime(createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.teal,
                                                      ),
                                                      onPressed: () =>
                                                          _showForm(
                                                              diary['id']),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.redAccent,
                                                      ),
                                                      onPressed: () =>
                                                          _deleteDiary(
                                                              diary['id']),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
