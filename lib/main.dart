import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reminder/noti_service.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  // Widget binding
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Timezone initialization
  tz.initializeTimeZones();

  // Notification initialization
  await NotiService().initNotification();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ReminderListScreen());
  }
}

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("My Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("reminder").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data!.docs;

          if (reminders.isEmpty) {
            return const Center(child: Text("No reminders yet!"));
          }

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final doc = reminders[index];
              final data = doc.data() as Map<String, dynamic>;

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(data['title'] ?? 'Untitled'),
                    subtitle: Text(data['description'] ?? ''),
                    trailing: Text(data['datetime'].toString()),
                    onLongPress: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () => Navigator.pop(context, 'edit'),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text('Delete'),
                                  onTap: () => Navigator.pop(context, 'delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (selected == 'delete') {
                        await db.collection('reminder').doc(doc.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reminder deleted 🗑️')),
                        );
                      } else if (selected == 'edit') {
                        // 👇 Navigate to edit form
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditReminder(docId: doc.id, existingData: data),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReminder()),
          );

          // To test instant notification
          // NotiService().showNotification(id:1, title: "title", body: "body");

          // To test scheduled notification
          // await NotiService().scheduleNotification(
          //   id: 5,
          //   title: "Reminder",
          //   body: "Drink water!",
          //   scheduledDate: DateTime.now().add(Duration(seconds: 7)),
          // );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ======================== ADD FORM ========================

class AddReminder extends StatefulWidget {
  const AddReminder({super.key});

  @override
  State<AddReminder> createState() => _AddReminderState();
}

class _AddReminderState extends State<AddReminder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Reminder")),
      body: const ReminderForm(),
    );
  }
}

// ======================== EDIT FORM ========================

class EditReminder extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> existingData;

  const EditReminder({
    super.key,
    required this.docId,
    required this.existingData,
  });

  @override
  State<EditReminder> createState() => _EditReminderState();
}

class _EditReminderState extends State<EditReminder> {
  final _formKey = GlobalKey<FormState>();
  final db = FirebaseFirestore.instance;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _datetimeController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingData['title'],
    );
    _descController = TextEditingController(
      text: widget.existingData['description'],
    );
    _datetimeController = TextEditingController(
      text: widget.existingData['datetime'].toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _datetimeController.dispose();
    super.dispose();
  }

  Future<void> _updateReminder() async {
    if (_formKey.currentState!.validate()) {
      await db.collection('reminder').doc(widget.docId).update({
        'title': _titleController.text,
        'description': _descController.text,
        'datetime': _datetimeController.text,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder updated! ✏️')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              TextFormField(
                controller: _datetimeController,
                decoration: const InputDecoration(labelText: 'Datetime'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateReminder,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== ADD FORM WIDGET ========================

class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key});

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  final db = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _datetimeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _datetimeController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await db.collection("reminder").add({
        "title": _titleController.text,
        "description": _descController.text,
        "datetime": _datetimeController.text,
        "createdAt": Timestamp.now(),
      });

      await NotiService().scheduleNotification(
        id: 1,
        title: _titleController.text,
        body: _descController.text,
        scheduledDate: DateTime.parse(_datetimeController.text),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder added! 🎉')));

      Navigator.pop(context);
    }
  }

  // Datetime picker widget testing

  DateTime? selectedDate;

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    setState(() {
      selectedDate = pickedDate;
    });
  }

  // Time of day picker widget testing

  TimeOfDay? selectedTime;

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    setState(() {
      selectedTime = pickedTime;
    });
  }

  void _selectDataTime() async {
    await _selectDate();
    await _selectTime();
    if (selectedDate != null && selectedTime != null) {
      final datetimeString =
          '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} ${selectedTime!.hour}:${selectedTime!.minute}';
      _datetimeController.text = datetimeString;
      final combinedDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      print(combinedDateTime);
      _datetimeController.text = combinedDateTime.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a title'
                  : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a description'
                  : null,
            ),
            TextFormField(
              controller: _datetimeController,
              decoration: const InputDecoration(labelText: 'Datetime'),
              onTap: _selectDataTime,
              readOnly: true,
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitForm, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
