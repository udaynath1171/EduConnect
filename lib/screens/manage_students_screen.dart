import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All Students',
          style: GoogleFonts.archivo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('students')
                .orderBy('first_name')
                .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('No students found', style: GoogleFonts.archivo()),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i].data()! as Map<String, dynamic>;
              final fullName = '${d['first_name']} ${d['last_name']}';
              final photoUrl = d['photo_url'] as String? ?? '';

              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl.isEmpty
                          ? Text(
                            d['first_name'][0],
                            style: GoogleFonts.archivo(
                              color: Colors.deepPurple,
                            ),
                          )
                          : null,
                ),
                title: Text(fullName, style: GoogleFonts.archivo()),
                subtitle: Text(
                  'Grade: ${d['grade']}',
                  style: GoogleFonts.archivo(),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/student-detail',
                      arguments: docs[i].id,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
