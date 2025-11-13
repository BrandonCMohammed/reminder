import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // var db = FirebaseFirestore.instance;


  // await db.collection("reminder").get().then((event) {
  //   for (var doc in event.docs) {
  //     print("${doc.id} => ${doc.data()}");
  //   }
  // });
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
        // 👇 Real-time updates from Firestore
        stream: db.collection("reminder").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extract the documents
          final reminders = snapshot.data!.docs;

          if (reminders.isEmpty) {
            return const Center(child: Text("No reminders yet!"));
          }

          // 👇 Build a scrollable list
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final data = reminders[index].data() as Map<String, dynamic>;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(data['title'] ?? 'Untitled'),
                    subtitle: Text(data['description'] ?? ''),
                    trailing: Text(data['datetime'].toString()),
                    onTap: () {
                      // Handle tap if needed
                      print(data['title']);
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReminder()),
          );
          // Handle adding a new reminder
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
      body: ReminderForm(),
    );
  }
}

class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key});

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _datetimeController = TextEditingController();

  final db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _datetimeController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await db.collection("reminder").add({
          "title": _titleController.text,
          "description": _descController.text,
          "datetime": _datetimeController.text,
          "createdAt": Timestamp.now(),
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder added! 🎉')));

        Navigator.pop(context); // Go back to list
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding reminder: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: const InputDecoration(labelText: 'Title'),
              controller: _titleController,
            ),
          ),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
            decoration: const InputDecoration(labelText: 'Description'),
            controller: _descController,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Datetime'),
            controller: _datetimeController,
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// C:\Users\00015403\AppData\Local\Pub\Cache\bin
