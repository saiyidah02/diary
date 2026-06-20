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
  // This function is used to fetch all data from the database
  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
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
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _feelingController,
                    decoration: const InputDecoration(hintText: 'Feeling'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new diary
                      if (id == null) {
                        await _addDiary();
                      }

                      if (id != null) {
                        await _updateDiary(id);
                      }

                      // Clear the text fields
                      _feelingController.text = '';
                      _descriptionController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

// Insert a new diary to the database
  Future<void> _addDiary() async {
    await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Update an existing diary
  Future<void> _updateDiary(int id) async {
    await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text);
    _refreshDiaries();
  }

  // Delete an item
  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a diary!'),
    ));
    _refreshDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Diary"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _diaries.isEmpty
              ? const Center(
                  child: Text(
                    'No diary entries yet. Tap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) {
                    final diary = _diaries[index];
                    return Card(
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/happy.gif',
                              fit: BoxFit.cover,
                              width: 42,
                              height: 42,
                            ),
                          ),
                        ),
                        title: Text(
                          diary['feeling'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                diary['description'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                diary['createdAt'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showForm(diary['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteDiary(diary['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.grey),
                onPressed: _recordVoiceNote,
                tooltip: 'Record voice note',
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _showEntryOptions,
      ),
    );
  }

  void _showEntryOptions() {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.teal),
                title: const Text('Add text entry'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showForm(null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.teal),
                title: const Text('Add emoji entry'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showForm(null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.grey),
                title: const Text('Add voice entry'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addVoiceEntry();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addVoiceEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Voice entry recording not implemented yet.')),
    );
  }

  void _recordVoiceNote() {
    _addVoiceEntry();
  }
}
