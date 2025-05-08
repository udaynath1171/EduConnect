import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/teacher_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/manage_students_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/edit_profile_screen.dart'; // ← IMPORT IT HERE

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        textTheme: GoogleFonts.archivoTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/home': (ctx) => const TeacherHomePage(),
        '/profile': (ctx) => const ProfileScreen(),
        '/manage-students': (ctx) => const ManageStudentsScreen(),
        '/edit-profile': (ctx) => const EditProfileScreen(), // ← REGISTER IT
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/student-detail') {
          final studentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: studentId),
          );
        }
        return null;
      },
    );
  }
}
