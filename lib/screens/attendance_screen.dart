import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/twilio_service.dart'; // WhatsApp Service
import 'submission_success_screen.dart'; // After submission screen

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final int studentsPerPage = 10;
  int currentPage = 1;
  Map<String, String> selectedStatus = {}; // studentId → "Present"/"Absent"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Attendance',
          style: GoogleFonts.archivo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('students').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // All students in the class:
              final docs = snapshot.data!.docs;
              final allStudentIds = docs.map((d) => d.id).toSet();

              // Pagination logic:
              final totalPages = (docs.length / studentsPerPage).ceil();
              final start = (currentPage - 1) * studentsPerPage;
              final end = (start + studentsPerPage).clamp(0, docs.length);
              final pageItems = docs.sublist(start, end);

              // Are we marked for everyone?
              final allMarked = selectedStatus.keys.toSet().containsAll(
                allStudentIds,
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: pageItems.length,
                      itemBuilder: (ctx, i) {
                        final doc = pageItems[i];
                        final data = doc.data()! as Map<String, dynamic>;
                        final fullName =
                            "${data['first_name']} ${data['last_name']}";
                        final photoUrl = data['photo_url'] as String?;
                        return _buildStudentRow(
                          doc.id,
                          data['first_name'] as String,
                          fullName,
                          photoUrl,
                        );
                      },
                    ),
                  ),

                  // pagination controls
                  _buildPagination(totalPages),
                  const SizedBox(height: 10),

                  // Cancel + Send buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              () => setState(() => selectedStatus.clear()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9CA3AF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.archivo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          // only enabled once everyone is marked
                          onPressed: allMarked ? submitAttendance : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7366FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Send',
                            style: GoogleFonts.archivo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: GoogleFonts.archivo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.archivo(),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 0)
            Navigator.pushNamed(context, '/home');
          else if (index == 1)
            Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    String studentId,
    String firstName,
    String fullName,
    String? photoUrl,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildAvatar(firstName, photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              fullName,
              style: GoogleFonts.archivo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildStatusButton(studentId, 'Present', Colors.green),
          const SizedBox(width: 8),
          _buildStatusButton(studentId, 'Absent', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildAvatar(String firstName, String? photoUrl) {
    final hasPhoto = photoUrl != null && photoUrl.startsWith('http');
    if (!hasPhoto) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.deepPurple.shade100,
        child: Text(
          firstName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      imageBuilder:
          (ctx, imageProvider) => CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: imageProvider,
          ),
      placeholder:
          (ctx, url) => CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.shade100,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
      errorWidget:
          (ctx, url, error) => CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              firstName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
    );
  }

  Widget _buildStatusButton(String studentId, String status, Color color) {
    final isSelected = selectedStatus[studentId] == status;
    return ElevatedButton(
      onPressed: () => setState(() => selectedStatus[studentId] = status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.8) : color,
        minimumSize: const Size(80, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status,
            style: GoogleFonts.archivo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check, size: 16, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              currentPage > 1 ? () => setState(() => currentPage--) : null,
        ),
        for (int i = 1; i <= totalPages; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => setState(() => currentPage = i),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    i == currentPage ? Colors.deepPurple : Colors.white,
                foregroundColor: i == currentPage ? Colors.white : Colors.black,
                minimumSize: const Size(36, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text('$i'),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              currentPage < totalPages
                  ? () => setState(() => currentPage++)
                  : null,
        ),
      ],
    );
  }

  Future<void> submitAttendance() async {
    final db = FirebaseFirestore.instance;
    final teacherId = FirebaseAuth.instance.currentUser!.uid;
    final date = DateTime.now();

    try {
      for (final entry in selectedStatus.entries) {
        final sid = entry.key;
        final stat = entry.value;

        final sdoc = await db.collection('students').doc(sid).get();
        final sData = sdoc.data()!;
        final name = "${sData['first_name']} ${sData['last_name']}";
        final pid = sData['parent_id'];

        final pdoc = await db.collection('parents').doc(pid).get();
        final pData = pdoc.data()!;
        final waNum = pData['whatsapp_number'];

        await db.collection('attendance_records').add({
          'student_id': sid,
          'student_name': name,
          'teacher_id': teacherId,
          'date': date,
          'status': stat,
          'parent_whatsapp_number': waNum,
        });

        await TwilioService.sendWhatsAppMessage(
          to: waNum,
          messageBody: "Attendance Update: $name is marked $stat.",
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted and WhatsApp sent!'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubmissionSuccessScreen()),
      );
    } catch (e) {
      debugPrint('❌ Error submitting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit attendance: $e')),
      );
    }
  }
}
