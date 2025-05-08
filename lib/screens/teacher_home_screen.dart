import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Placeholder Screens for navigation (Create these files separately)
import 'attendance_screen.dart';
import 'assignment_screen.dart';
import 'behaviour_screen.dart';
import 'announcement_screen.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String firstName = '';

  @override
  void initState() {
    super.initState();
    fetchFirstName();
  }

  Future<void> fetchFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        setState(() {
          firstName = doc.data()?['first_name'] ?? '';
        });
      }
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Hello${firstName.isNotEmpty ? ', $firstName' : ''}',
                style: GoogleFonts.archivo(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCard(
                    context,
                    title: 'Attendance',
                    icon: Icons.check_circle_outline,
                    onTap: () => _navigateTo(context, const AttendanceScreen()),
                  ),
                  _buildDivider(),
                  _buildCard(
                    context,
                    title: 'Assignment',
                    icon: Icons.assignment_outlined,
                    onTap: () => _navigateTo(context, const AssignmentScreen()),
                  ),
                  _buildDivider(),
                  _buildCard(
                    context,
                    title: 'Behaviour',
                    icon: Icons.star_border,
                    onTap: () => _navigateTo(context, const BehaviourScreen()),
                  ),
                  _buildDivider(),
                  _buildCard(
                    context,
                    title: 'General Announcement',
                    icon: Icons.message_outlined,
                    onTap:
                        () => _navigateTo(
                          context,
                          const GeneralAnnouncementScreen(),
                        ),
                  ),
                ],
              ),
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
        currentIndex: 0, // 🏠 Because this is Home Page
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home'); // Stay or refresh Home
          } else if (index == 1) {
            Navigator.pushNamed(
              context,
              '/profile',
            ); // Navigate to Profile Screen
          }
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

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: Colors.deepPurple.withOpacity(0.2), // subtle wave
      child: Container(
        width: double.infinity,
        height: 113,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F171A1F),
              blurRadius: 2,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color(0x12171A1F),
              blurRadius: 1,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.archivo(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121481),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 16);
  }
}
