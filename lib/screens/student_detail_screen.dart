import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  const StudentDetailScreen({required this.studentId, super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<_StudentWithParent> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadStudentAndParent();
  }

  Future<_StudentWithParent> _loadStudentAndParent() async {
    // 1) Fetch student document
    final studentSnap =
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .get();
    if (!studentSnap.exists) {
      throw Exception('Student not found');
    }
    final sd = studentSnap.data()! as Map<String, dynamic>;

    // 2) Fetch parent document by parent_id
    final parentId = sd['parent_id'] as String;
    final parentSnap =
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();
    if (!parentSnap.exists) {
      throw Exception('Parent not found');
    }
    final pd = parentSnap.data()! as Map<String, dynamic>;

    // 3) Safely format parent's WhatsApp number
    final raw = pd['whatsapp_number'].toString(); // e.g. "4235551234"
    late final String formattedParentPhone;
    if (raw.length == 10) {
      formattedParentPhone =
          '(${raw.substring(0, 3)}) '
          '${raw.substring(3, 6)}-'
          '${raw.substring(6)}';
    } else {
      formattedParentPhone = raw;
    }

    return _StudentWithParent(
      firstName: sd['first_name'] as String,
      lastName: sd['last_name'] as String,
      photoUrl: sd['photo_url'] as String,
      parentName: '${pd['first_name']} ${pd['last_name']}',
      parentPhoneFormatted: formattedParentPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentWithParent>(
      future: _detailFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(snap.error.toString())),
          );
        }

        final d = snap.data!;
        final fullName = '${d.firstName} ${d.lastName}';

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              fullName,
              style: GoogleFonts.archivo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(d.photoUrl),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                _buildField('First Name', d.firstName),
                _buildField('Last Name', d.lastName),
                const Divider(height: 32),
                _buildField('Parent Name', d.parentName),
                _buildField('Parent Phone', d.parentPhoneFormatted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: GoogleFonts.archivo(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _StudentWithParent {
  final String firstName;
  final String lastName;
  final String photoUrl;
  final String parentName;
  final String parentPhoneFormatted;

  _StudentWithParent({
    required this.firstName,
    required this.lastName,
    required this.photoUrl,
    required this.parentName,
    required this.parentPhoneFormatted,
  });
}
