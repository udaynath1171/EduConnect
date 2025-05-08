import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageParentsScreen extends StatefulWidget {
  const ManageParentsScreen({super.key});

  @override
  State<ManageParentsScreen> createState() => _ManageParentsScreenState();
}

class _ManageParentsScreenState extends State<ManageParentsScreen> {
  final parentsRef = FirebaseFirestore.instance.collection('parents');

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Future<void> addOrEditParent({String? docId}) async {
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
      // Add new parent
      await parentsRef.add({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
    } else {
      // Edit existing parent
      await parentsRef.doc(docId).update({
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

  Future<void> showParentDialog({String? docId, Map<String, dynamic>? data}) {
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
            title: Text(docId == null ? 'Add Parent' : 'Edit Parent'),
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
                onPressed: () => addOrEditParent(docId: docId),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> deleteParent(String docId) async {
    await parentsRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showParentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: parentsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No parents found.'));
          }

          var parents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: parents.length,
            itemBuilder: (context, index) {
              var parent = parents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text('${parent['first_name']} ${parent['last_name']}'),
                  subtitle: Text(parent['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            () => showParentDialog(
                              docId: parent.id,
                              data: parent.data() as Map<String, dynamic>,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteParent(parent.id),
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
