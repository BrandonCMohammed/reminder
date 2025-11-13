import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var db = FirebaseFirestore.instance;

  // Create a new user with a first and last name
  final reminder = <String, dynamic>{
    "id": 3,
    "title": "Ada",
    "description": "Lovelace",
    "datetime": 1815,
  };

  // Add a new document with a generated ID
  db
      .collection("reminder")
      .add(reminder)
      .then(
        (DocumentReference doc) =>
            print('DocumentSnapshot added with ID: ${doc.id}'),
      );

  await db.collection("reminder").get().then((event) {
    for (var doc in event.docs) {
      print("${doc.id} => ${doc.data()}");
    }
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ReminderListScreen(),
    );
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
    );
  }
}
// C:\Users\00015403\AppData\Local\Pub\Cache\bin
