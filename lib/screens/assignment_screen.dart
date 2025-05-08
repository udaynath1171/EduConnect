import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/twilio_service.dart'; // WhatsApp Service
import 'submission_success_screen.dart'; // Success screen

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _homeworkController = TextEditingController();

  bool selectAllStudents = false;
  Set<String> selectedStudentIds = {};

  String? _attachmentBase64;
  String? _attachmentName;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    // pre‑select all students
    FirebaseFirestore.instance.collection('students').get().then((snap) {
      setState(() {
        selectAllStudents = true;
        selectedStudentIds = snap.docs.map((d) => d.id as String).toSet();
      });
    });
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _homeworkController.text.trim().isNotEmpty &&
      selectedStudentIds.isNotEmpty &&
      _deadline != null;

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    setState(() {
      _attachmentName = file.name;
      _attachmentBase64 = base64Encode(file.bytes!);
    });
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          _deadline != null
              ? TimeOfDay.fromDateTime(_deadline!)
              : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String get _deadlineText {
    if (_deadline == null) return 'Pick deadline';
    return DateFormat('EEE, MMM d, yyyy – h:mm a').format(_deadline!);
  }

  Future<void> submitAssignment() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill title, details, select students, and set a deadline.',
          ),
        ),
      );
      return;
    }

    final db = FirebaseFirestore.instance;
    final teacherId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1) Save assignment doc
      await db.collection('assignments').add({
        'title': _titleController.text.trim(),
        'description': _homeworkController.text.trim(),
        'attachment_name': _attachmentName,
        'attachment_base64': _attachmentBase64,
        'teacher_id': teacherId,
        'timestamp': DateTime.now(),
        'deadline': Timestamp.fromDate(_deadline!),
        'students': selectedStudentIds.toList(),
      });

      // 2) Notify each selected student's parent
      for (final sid in selectedStudentIds) {
        final studentSnap = await db.collection('students').doc(sid).get();
        if (!studentSnap.exists) continue;
        final data = studentSnap.data()!;
        final firstName = data['first_name'] as String;
        final parentId = data['parent_id'] as String;
        final parentSnap = await db.collection('parents').doc(parentId).get();
        if (!parentSnap.exists) continue;
        final whatsapp = parentSnap.data()!['whatsapp_number'] as String;

        final msg =
            StringBuffer()
              ..writeln("👋 Hello $firstName’s parent,")
              ..writeln()
              ..writeln("*📚 New Assignment Posted!*")
              ..writeln()
              ..writeln("*Title:* ${_titleController.text.trim()}")
              ..writeln("*Details:* ${_homeworkController.text.trim()}")
              ..writeln(
                _attachmentName != null ? "*Attachment:* $_attachmentName" : "",
              )
              ..writeln()
              ..writeln(
                "🕒 _Please complete this by ${DateFormat('EEE, MMM d, yyyy h:mm a').format(_deadline!)}_",
              )
              ..writeln()
              ..writeln("👍 Reply if you have any questions.")
              ..writeln()
              ..writeln("Warmly,")
              ..writeln("Your Teacher");

        await TwilioService.sendWhatsAppMessage(
          to: whatsapp,
          messageBody: msg.toString(),
        );
      }

      // On success, navigate to success screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SubmissionSuccessScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error sending assignment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send assignment: $e')));
      // stay on form for retry
    }
  }

  void _resetForm() {
    _titleController.clear();
    _homeworkController.clear();
    setState(() {
      _attachmentBase64 = null;
      _attachmentName = null;
      _deadline = null;
      selectAllStudents = true;
      FirebaseFirestore.instance.collection('students').get().then((snap) {
        selectedStudentIds = snap.docs.map((d) => d.id as String).toSet();
        setState(() {});
      });
    });
  }

  void _onSelectAllChanged(bool? value) {
    setState(() {
      selectAllStudents = value ?? false;
      if (selectAllStudents) {
        FirebaseFirestore.instance.collection('students').get().then((snap) {
          selectedStudentIds = snap.docs.map((d) => d.id as String).toSet();
          setState(() {});
        });
      } else {
        selectedStudentIds.clear();
      }
    });
  }

  void _onStudentToggled(String sid, bool? val) {
    setState(() {
      if (val == true) {
        selectedStudentIds.add(sid);
      } else {
        selectedStudentIds.remove(sid);
        selectAllStudents = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Assignment',
          style: GoogleFonts.archivo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Title / Details / Attach / Deadline
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'TITLE',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _homeworkController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type down the homework...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  ElevatedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      _attachmentName ?? 'Attach File',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7366FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      _deadlineText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Select Students',
              style: GoogleFonts.archivo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12171A1F),
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Row(
                      children: [
                        Checkbox(
                          value: selectAllStudents,
                          onChanged: _onSelectAllChanged,
                          activeColor: const Color(0xFF7366FF),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'All Students',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    children: [
                      for (var doc in docs)
                        CheckboxListTile(
                          title: Text(
                            "${doc['first_name']} ${doc['last_name']}",
                          ),
                          value: selectedStudentIds.contains(doc.id),
                          activeColor: const Color(0xFF7366FF),
                          onChanged: (val) => _onStudentToggled(doc.id, val),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetForm,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSubmit ? submitAssignment : null,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: GoogleFonts.archivo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.archivo(),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) {
          if (i == 0)
            Navigator.pushNamed(context, '/home');
          else if (i == 1)
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
}
