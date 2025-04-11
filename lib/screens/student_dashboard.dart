import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;
  int _currentIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
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
    _nameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _user = UserModel.fromFirestore(userDoc);
          _nameController.text = _user!.name;
          _emailController.text = _user!.email;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      setState(() {
        _user = UserModel(
          uid: _user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _user!.role,
          createdAt: _user!.createdAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyForInternship(String internshipId) async {
    try {
      // Check if already applied
      var existingApplication =
          await _firestore
              .collection('applications')
              .where('studentId', isEqualTo: _auth.currentUser!.uid)
              .where('internshipId', isEqualTo: internshipId)
              .get();

      if (existingApplication.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already applied for this internship'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      var internshipDoc =
          await _firestore.collection('internships').doc(internshipId).get();
      var internship = internshipDoc.data()!;

      await _firestore.collection('applications').add({
        'studentId': _auth.currentUser!.uid,
        'studentName': _user!.name,
        'studentEmail': _user!.email,
        'internshipId': internshipId,
        'internshipTitle': internship['title'],
        'companyName': internship['companyName'],
        'employerId': internship['employerId'],
        'status': 'Pending',
        'appliedAt': Timestamp.now(),
      });

      await _firestore.collection('internships').doc(internshipId).update({
        'applications': FieldValue.arrayUnion([_auth.currentUser!.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying for internship: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    if (_user == null) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD3AC), Color(0xFFFFB5AB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFFFF5F0),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFFE39A7B),
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _user?.name ?? 'User',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF4A4A4A)),
                        onPressed: _showEditProfileDialog,
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Color(0xFF4A4A4A)),
                        onPressed: _signOut,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    value: _user?.email ?? 'Not set',
                  ),
                  _buildInfoCard(
                    icon: Icons.work,
                    title: 'Role',
                    value: _user?.role ?? 'Student',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    _nameController.text = _user!.name;
    _emailController.text = _user!.email;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFE39A7B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Color(0xFFE39A7B),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE39A7B).withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: Color(0xFF4A4A4A)),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Color(0xFF666666)),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Color(0xFFE39A7B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFE39A7B)),
                            ),
                            filled: true,
                            fillColor: Color(0xFFFFF5F0),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: Color(0xFF4A4A4A)),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Color(0xFF666666)),
                            prefixIcon: Icon(
                              Icons.email,
                              color: Color(0xFFE39A7B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFE39A7B)),
                            ),
                            filled: true,
                            fillColor: Color(0xFFFFF5F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _updateProfile();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error updating profile: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE39A7B),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFFFF5F0).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFFE39A7B), size: 24),
          SizedBox(height: 5),
          Text(title, style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('internships').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var internships = snapshot.data!.docs;
        if (internships.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 50, color: Colors.grey[400]),
                SizedBox(height: 10),
                Text(
                  'No internships available yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: internships.length,
          itemBuilder: (context, index) {
            var internship = internships[index];
            var internshipData = internship.data() as Map<String, dynamic>;

            return StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('applications')
                      .where('studentId', isEqualTo: _auth.currentUser!.uid)
                      .where('internshipId', isEqualTo: internship.id)
                      .snapshots(),
              builder: (context, applicationSnapshot) {
                bool hasApplied =
                    applicationSnapshot.hasData &&
                    applicationSnapshot.data!.docs.isNotEmpty;
                String status =
                    hasApplied
                        ? applicationSnapshot.data!.docs.first['status']
                        : '';

                return Container(
                  margin: EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15),
                    title: Text(
                      internshipData['title'] ?? 'Untitled Internship',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internshipData['companyName'] ?? 'Unknown Company',
                        ),
                        Text(
                          internshipData['location'] ??
                              'Location not specified',
                        ),
                        SizedBox(height: 10),
                        if (internshipData['deadline'] != null)
                          Text(
                            'Deadline: ${(internshipData['deadline'] as Timestamp).toDate().toString().split(' ')[0]}',
                            style: TextStyle(color: Colors.red),
                          ),
                        if (hasApplied)
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing:
                        hasApplied
                            ? Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : ElevatedButton(
                              onPressed:
                                  () => _applyForInternship(internship.id),
                              child: Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE39A7B),
                                elevation: 0,
                              ),
                            ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApplicationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('applications')
              .where('studentId', isEqualTo: _auth.currentUser!.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE39A7B)),
            ),
          );
        }

        var applications = snapshot.data!.docs;
        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 50,
                  color: Color(0xFFE39A7B).withOpacity(0.5),
                ),
                SizedBox(height: 10),
                Text(
                  'No records found',
                  style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                ),
              ],
            ),
          );
        }

        applications.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          var aTime = aData['appliedAt'] as Timestamp?;
          var bTime = bData['appliedAt'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            var application = applications[index];
            var applicationData = application.data() as Map<String, dynamic>;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE39A7B).withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    title: Text(
                      applicationData['internshipTitle'] ??
                          'Untitled Internship',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${applicationData['status'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: _getStatusColor(
                          applicationData['status'] ?? 'Unknown',
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFE39A7B),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Company: ${applicationData['companyName'] ?? 'Unknown Company'}',
                              style: TextStyle(color: Color(0xFF4A4A4A)),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Application Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFE39A7B),
                              ),
                            ),
                            SizedBox(height: 10),
                            if (applicationData['appliedAt'] != null)
                              Text(
                                'Applied on: ${(applicationData['appliedAt'] as Timestamp).toDate().toString().split(' ')[0]}',
                                style: TextStyle(color: Color(0xFF4A4A4A)),
                              ),
                            if (applicationData['status'] == 'Rejected')
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'Note: Your application was not selected for this position',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5F0),
      body:
          _user == null
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE39A7B)),
                ),
              )
              : Column(
                children: [
                  _buildProfileHeader(),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollBehavior().copyWith(
                        physics: BouncingScrollPhysics(),
                        scrollbars: false,
                      ),
                      child:
                          _currentIndex == 0
                              ? _buildInternshipsSection()
                              : _buildApplicationsSection(),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFFE39A7B),
        unselectedItemColor: Color(0xFF4A4A4A).withAlpha(128),
        backgroundColor: Color(0xFFFFF5F0),
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Internships'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
