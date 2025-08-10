import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_to_do_app/firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('To-Do List'),
        ),
        body: const ToDoList(),
      ),
    );
  }
}

class ToDoList extends StatefulWidget {
  const ToDoList({super.key});

  @override
  State<ToDoList> createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final TextEditingController _controller = TextEditingController();

  final CollectionReference _tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> _addTask() async {
    if (_controller.text.isNotEmpty) {
      await _tasksCollection.add({
        'task': _controller.text,
        'timestamp': FieldValue.serverTimestamp()
      });
      _controller.clear();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter a new task',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTask,
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _tasksCollection.orderBy('timestamp').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading tasks'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No tasks available'));
              }
              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task['task']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('No tasks available'));
            },
          ),
        ),
      ],
    );
  }
}
