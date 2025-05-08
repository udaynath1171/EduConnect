import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final studentsRef = FirebaseFirestore.instance.collection('students');
  final coursesRef = FirebaseFirestore.instance.collection('courses');
  final parentsRef = FirebaseFirestore.instance.collection('parents');

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  String? selectedCourseId;
  String? selectedParentId;

  Future<void> addOrEditStudent({String? docId}) async {
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        selectedCourseId == null ||
        selectedParentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    if (docId == null) {
      // Add new student
      await studentsRef.add({
        'first_name': firstName,
        'last_name': lastName,
        'course_id': selectedCourseId,
        'parent_id': selectedParentId,
      });
    } else {
      // Edit existing student
      await studentsRef.doc(docId).update({
        'first_name': firstName,
        'last_name': lastName,
        'course_id': selectedCourseId,
        'parent_id': selectedParentId,
      });
    }

    firstNameController.clear();
    lastNameController.clear();
    selectedCourseId = null;
    selectedParentId = null;
    Navigator.pop(context);
  }

  Future<void> showStudentDialog({
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    if (data != null) {
      firstNameController.text = data['first_name'];
      lastNameController.text = data['last_name'];
      selectedCourseId = data['course_id'];
      selectedParentId = data['parent_id'];
    } else {
      firstNameController.clear();
      lastNameController.clear();
      selectedCourseId = null;
      selectedParentId = null;
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(docId == null ? 'Add Student' : 'Edit Student'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: coursesRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      var courses = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCourseId,
                        hint: const Text('Select Course'),
                        items:
                            courses.map((course) {
                              return DropdownMenuItem<String>(
                                value: course.id,
                                child: Text(course['course_name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCourseId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: parentsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      var parents = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedParentId,
                        hint: const Text('Select Parent'),
                        items:
                            parents.map((parent) {
                              return DropdownMenuItem<String>(
                                value: parent.id,
                                child: Text(
                                  '${parent['first_name']} ${parent['last_name']}',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedParentId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => addOrEditStudent(docId: docId),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> deleteStudent(String docId) async {
    await studentsRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showStudentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          var students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var student = students[index];
              return FutureBuilder<DocumentSnapshot>(
                future: coursesRef.doc(student['course_id']).get(),
                builder: (context, courseSnapshot) {
                  String courseName = '';
                  if (courseSnapshot.hasData && courseSnapshot.data!.exists) {
                    courseName = courseSnapshot.data!['course_name'];
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${student['first_name']} ${student['last_name']}',
                      ),
                      subtitle: Text('Course: $courseName'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => showStudentDialog(
                                  docId: student.id,
                                  data: student.data() as Map<String, dynamic>,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteStudent(student.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
