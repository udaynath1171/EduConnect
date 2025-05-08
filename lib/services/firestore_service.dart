import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static Future<void> submitAttendance({
    required String courseId,
    required String courseName,
    required Map<String, String> attendanceData,
  }) async {
    final db = FirebaseFirestore.instance;
    final teacherId = FirebaseAuth.instance.currentUser!.uid;
    final date = DateTime.now();

    for (var entry in attendanceData.entries) {
      var studentId = entry.key;
      var status = entry.value;

      final studentDoc = await db.collection('students').doc(studentId).get();
      final parentDoc =
          await db.collection('parents').doc(studentDoc['parent_id']).get();

      await db.collection('attendance_records').add({
        'student_id': studentId,
        'student_name':
            '${studentDoc['first_name']} ${studentDoc['last_name']}',
        'course_id': courseId,
        'course_name': courseName,
        'teacher_id': teacherId,
        'date': date,
        'status': status,
        'parent_whatsapp_number': parentDoc['whatsapp_number'],
      });
    }
  }
}
