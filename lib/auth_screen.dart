import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String selectedRole = 'Student';
  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  void _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    try {
      if (email == 'admin@gmail.com' && password == 'admin@1') {
        var adminQuery =
            await _firestore
                .collection('users')
                .where('email', isEqualTo: 'admin@gmail.com')
                .get();

        if (adminQuery.docs.isEmpty) {
          UserCredential adminCredential = await _auth
              .createUserWithEmailAndPassword(
                email: 'admin@gmail.com',
                password: 'admin@1',
              );

          await _firestore
              .collection('users')
              .doc(adminCredential.user!.uid)
              .set({
                'email': 'admin@gmail.com',
                'name': 'Admin',
                'role': 'Admin',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        _navigateToDashboard('Admin');
        return;
      }

      UserCredential userCredential;

      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        DocumentSnapshot userDoc =
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          _navigateToDashboard(role);
        } else {
          throw 'User data not found';
        }
      } else {
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter your name'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(10),
            ),
          );
          setState(() => isLoading = false);
          return;
        }

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _navigateToDashboard(selectedRole);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered. Please login instead.';
          break;
        case 'weak-password':
          message = 'Password should be at least 6 characters long.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'operation-not-allowed':
          message = 'This operation is not allowed. Please contact support.';
          break;
        default:
          message = 'Something went wrong. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role) {
    if (role == "Student") {
      Navigator.pushReplacementNamed(context, '/student_dashboard');
    } else if (role == "Employer") {
      Navigator.pushReplacementNamed(context, '/employer_dashboard');
    } else if (role == "Admin") {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFD3AC), // Light warm color for background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD3AC), // Light warm color
              Color(0xFFFFD3AC).withAlpha(204), // 0.8 opacity = 204 alpha
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 40),
                      // Header Section
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 60,
                              color: Color(0xFFE39A7B),
                            ),
                            SizedBox(height: 24),
                            Text(
                              isLogin ? "Welcome Back!" : "Create Account",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              isLogin
                                  ? "Sign in to continue to your account"
                                  : "Join us to find your dream internship",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Form Section
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE39A7B).withAlpha(38),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isLogin) ...[
                                TextFormField(
                                  controller: nameController,
                                  style: TextStyle(color: Color(0xFF4A4A4A)),
                                  decoration: InputDecoration(
                                    labelText: "Full Name",
                                    labelStyle: TextStyle(
                                      color: Color(0xFF666666),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Color(0xFFE39A7B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B).withAlpha(77),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B).withAlpha(77),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFFFF5F0),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                              ],
                              TextFormField(
                                controller: emailController,
                                style: TextStyle(color: Color(0xFF4A4A4A)),
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF666666),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Color(0xFFE39A7B),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B).withAlpha(77),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B).withAlpha(77),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFFFF5F0),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!_isValidEmail(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: passwordController,
                                style: TextStyle(color: Color(0xFF4A4A4A)),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF666666),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Color(0xFFE39A7B),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B).withAlpha(77),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B).withAlpha(77),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE39A7B),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFFFF5F0),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!isLogin && !_isValidPassword(value)) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (!isLogin) ...[
                                SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  style: TextStyle(color: Color(0xFF4A4A4A)),
                                  items:
                                      ["Student", "Employer"].map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value!;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Select Role",
                                    labelStyle: TextStyle(
                                      color: Color(0xFF666666),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.people,
                                      color: Color(0xFFE39A7B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B).withAlpha(77),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B).withAlpha(77),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(0xFFE39A7B),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFFFF5F0),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      // Action Buttons
                      ElevatedButton(
                        onPressed: isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE39A7B),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isLoading
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(
                                      0xFFFFD3AC,
                                    ), // Light warm color for loading indicator
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  isLogin ? "Sign In" : "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                      0xFFFFF5F0,
                                    ), // Soft warm white for text
                                  ),
                                ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  setState(() {
                                    isLogin = !isLogin;
                                    if (isLogin) {
                                      nameController.clear();
                                    }
                                  });
                                },
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign up"
                              : "Already have an account? Sign in",
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
