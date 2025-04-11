import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/employer_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Internship App",
      home: AuthScreen(),
      routes: {
        '/student_dashboard': (context) => StudentDashboard(),
        '/employer_dashboard': (context) => EmployerDashboard(),
        '/admin_dashboard': (context) => AdminDashboard(),
      },
    );
  }
}
