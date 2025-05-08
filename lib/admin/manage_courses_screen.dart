import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final coursesRef = FirebaseFirestore.instance.collection('courses');
  final teachersRef = FirebaseFirestore.instance.collection('teachers');

  final TextEditingController courseNameController = TextEditingController();
  String? selectedTeacherId;

  Future<void> addOrEditCourse({String? docId}) async {
    String courseName = courseNameController.text.trim();

    if (courseName.isEmpty || selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course name and Teacher are required.')),
      );
      return;
    }

    if (docId == null) {
      // Add new course
      await coursesRef.add({
        'course_name': courseName,
        'teacher_id': selectedTeacherId,
      });
    } else {
      // Edit existing course
      await coursesRef.doc(docId).update({
        'course_name': courseName,
        'teacher_id': selectedTeacherId,
      });
    }

    courseNameController.clear();
    selectedTeacherId = null;
    Navigator.pop(context);
  }

  Future<void> showCourseDialog({
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    if (data != null) {
      courseNameController.text = data['course_name'];
      selectedTeacherId = data['teacher_id'];
    } else {
      courseNameController.clear();
      selectedTeacherId = null;
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(docId == null ? 'Add Course' : 'Edit Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseNameController,
                  decoration: const InputDecoration(labelText: 'Course Name'),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: teachersRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    var teachers = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedTeacherId,
                      hint: const Text('Select Teacher'),
                      items:
                          teachers.map((teacher) {
                            return DropdownMenuItem<String>(
                              value: teacher.id,
                              child: Text(
                                '${teacher['first_name']} ${teacher['last_name']}',
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTeacherId = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => addOrEditCourse(docId: docId),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> deleteCourse(String docId) async {
    await coursesRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showCourseDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: coursesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          var courses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index];
              return FutureBuilder<DocumentSnapshot>(
                future: teachersRef.doc(course['teacher_id']).get(),
                builder: (context, teacherSnapshot) {
                  String teacherName = '';
                  if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
                    var teacherData = teacherSnapshot.data!;
                    teacherName =
                        '${teacherData['first_name']} ${teacherData['last_name']}';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(course['course_name']),
                      subtitle: Text('Teacher: $teacherName'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => showCourseDialog(
                                  docId: course.id,
                                  data: course.data() as Map<String, dynamic>,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteCourse(course.id),
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
