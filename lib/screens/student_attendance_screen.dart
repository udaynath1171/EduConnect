import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/twilio_service.dart'; // 👈 Import the Twilio service you created
import 'package:firebase_auth/firebase_auth.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const StudentAttendanceScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final Map<String, String> attendanceMap = {}; // studentId -> Present/Absent

  Future<void> submitAttendance() async {
    final db = FirebaseFirestore.instance;
    final teacherId = FirebaseAuth.instance.currentUser!.uid;
    final date = DateTime.now();

    try {
      for (var entry in attendanceMap.entries) {
        var studentId = entry.key;
        var status = entry.value;

        // Fetch student document
        final studentDoc = await db.collection('students').doc(studentId).get();
        final parentDoc =
            await db.collection('parents').doc(studentDoc['parent_id']).get();

        final studentName =
            "${studentDoc['first_name']} ${studentDoc['last_name']}";
        final parentWhatsappNumber = parentDoc['whatsapp_number'];

        // Add attendance record
        await db.collection('attendance_records').add({
          'student_id': studentId,
          'student_name': studentName,
          'course_id': widget.courseId,
          'course_name': widget.courseName,
          'teacher_id': teacherId,
          'date': date,
          'status': status,
          'parent_whatsapp_number': parentWhatsappNumber,
        });

        // ✅ Send WhatsApp Message after saving
        await TwilioService.sendWhatsAppMessage(
          to: parentWhatsappNumber,
          messageBody:
              "Attendance Update: $studentName for ${widget.courseName} is marked $status.",
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance Submitted and WhatsApp sent!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error submitting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance - ${widget.courseName}')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('students')
                .where('course_id', isEqualTo: widget.courseId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          var students = snapshot.data!.docs;
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text(
                    "${student['first_name']} ${student['last_name']}",
                  ),
                  trailing: DropdownButton<String>(
                    value: attendanceMap[student.id] ?? 'Present',
                    items:
                        ['Present', 'Absent']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        attendanceMap[student.id] = value!;
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitAttendance,
        icon: const Icon(Icons.check),
        label: const Text('Submit Attendance'),
      ),
    );
  }
}
