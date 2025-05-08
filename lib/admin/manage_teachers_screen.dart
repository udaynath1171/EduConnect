import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final teachersRef = FirebaseFirestore.instance.collection('teachers');

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Future<void> addOrEditTeacher({String? docId}) async {
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    if (docId == null) {
      // Add new teacher
      await teachersRef.add({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
    } else {
      // Edit existing teacher
      await teachersRef.doc(docId).update({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
    }

    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    Navigator.pop(context);
  }

  Future<void> showTeacherDialog({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      firstNameController.text = data['first_name'];
      lastNameController.text = data['last_name'];
      emailController.text = data['email'];
    } else {
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(docId == null ? 'Add Teacher' : 'Edit Teacher'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => addOrEditTeacher(docId: docId),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> deleteTeacher(String docId) async {
    await teachersRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showTeacherDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teachersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teachers found.'));
          }

          var teachers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              var teacher = teachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text(
                    '${teacher['first_name']} ${teacher['last_name']}',
                  ),
                  subtitle: Text(teacher['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            () => showTeacherDialog(
                              docId: teacher.id,
                              data: teacher.data() as Map<String, dynamic>,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteTeacher(teacher.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
