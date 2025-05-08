import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_TeacherProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_TeacherProfile> _loadProfile() async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;

    // 1) Load your teacher record
    final snap =
        await FirebaseFirestore.instance
            .collection('teachers')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
    final data = snap.docs.first.data();

    // 2) Format the raw phone number
    final rawPhone = data['phone'].toString(); // e.g. "4236728800"
    final formattedPhone =
        '(${rawPhone.substring(0, 3)}) '
        '${rawPhone.substring(3, 6)}-'
        '${rawPhone.substring(6)}'; // "(423) 672-8800"

    // 3) Pull out the rest of your fields
    final firstName = data['first_name'] as String;
    final grade = data['grade'] as String;
    final photoUrl = data['photoUrl-teacher'] as String;

    // 4) Count **all** students in the 'students' collection
    final allStudentsSnap =
        await FirebaseFirestore.instance.collection('students').get();

    return _TeacherProfile(
      firstName: firstName,
      phone: formattedPhone,
      grade: grade,
      photoUrl: photoUrl,
      totalStudents: allStudentsSnap.docs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TeacherProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data!;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Profile',
              style: GoogleFonts.archivo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(profile.photoUrl),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.firstName,
                      style: GoogleFonts.archivo(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone,
                      style: GoogleFonts.archivo(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProfileStat(
                          'Total Students',
                          '${profile.totalStudents}',
                        ),
                        _buildProfileStat('Grade', profile.grade),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/manage-students',
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7366FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Manage Students',
                              style: GoogleFonts.archivo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/edit-profile',
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7366FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Edit Profile',
                              style: GoogleFonts.archivo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (r) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.archivo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedLabelStyle: GoogleFonts.archivo(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.archivo(),
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            currentIndex: 1,
            onTap: (i) {
              if (i == 0) Navigator.pushNamed(context, '/home');
              if (i == 1) Navigator.pushNamed(context, '/profile');
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
      },
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.archivo(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.archivo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Simple data holder for your profile
class _TeacherProfile {
  final String firstName;
  final String phone;
  final String grade;
  final String photoUrl;
  final int totalStudents;

  _TeacherProfile({
    required this.firstName,
    required this.phone,
    required this.grade,
    required this.photoUrl,
    required this.totalStudents,
  });
}
