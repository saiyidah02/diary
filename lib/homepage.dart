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

  bool _isLoading = true;

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
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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
              leading: const Icon(Icons.color_lens, color: Colors.pink),
              title: const Text('Theme'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Theme screen not implemented yet.')),
                );
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
              leading: const Icon(Icons.widgets, color: Colors.pink),
              title: const Text('Widget'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Widget screen not implemented yet.')),
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: _diaries.isEmpty
                      ? const Center(
                          child: Text(
                            'No diary entries yet. Tap + to add one.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          itemCount: _diaries.length,
                          itemBuilder: (context, index) {
                            final diary = _diaries[index];
                            final feeling = diary['feeling'] as String? ?? '';
                            final description =
                                diary['description'] as String? ?? '';
                            final createdAt = diary['createdAt'] as String?;
                            final displayEmoji = feeling.isNotEmpty &&
                                    RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}]',
                                            unicode: true)
                                        .hasMatch(feeling)
                                ? feeling
                                : '😊';

                            return Card(
                              color: Colors.pink[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                BorderRadius.circular(18),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _formatDiaryDay(createdAt),
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDiaryMonth(createdAt),
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                feeling,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
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
                                          backgroundColor: Colors.pink[100],
                                          child: Text(
                                            displayEmoji,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                  _showForm(diary['id']),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _deleteDiary(diary['id']),
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
