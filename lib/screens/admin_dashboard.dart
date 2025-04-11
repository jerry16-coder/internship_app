import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/internship_model.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      await _auth.currentUser?.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteInternship(String internshipId) async {
    try {
      await _firestore.collection('internships').doc(internshipId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Internship deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting internship: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUsersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE39A7B)),
            ),
          );
        }

        var users = snapshot.data!.docs;
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 50,
                  color: Color(0xFFE39A7B).withAlpha(128),
                ),
                SizedBox(height: 10),
                Text(
                  'No users found',
                  style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = UserModel.fromFirestore(users[index]);
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
                        color: Color(0xFFE39A7B).withAlpha(26),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFFFF5F0),
                      child: Icon(
                        user.role == 'Student' ? Icons.person : Icons.business,
                        color: Color(0xFFE39A7B),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                        Text(
                          'Role: ${user.role}',
                          style: TextStyle(
                            color: Color(0xFFE39A7B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Color(0xFFE39A7B)),
                      onPressed: () => _showDeleteUserDialog(user),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInternshipsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('internships').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE39A7B)),
            ),
          );
        }

        var internships = snapshot.data!.docs;
        if (internships.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 50,
                  color: Color(0xFFE39A7B).withAlpha(128),
                ),
                SizedBox(height: 10),
                Text(
                  'No internships posted yet',
                  style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: internships.length,
          itemBuilder: (context, index) {
            var internship = Internship.fromFirestore(internships[index]);
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
                        color: Color(0xFFE39A7B).withAlpha(26),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15),
                    title: Text(
                      internship.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship.companyName,
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                        Text(
                          internship.location,
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Applications: ${internship.applications.length}',
                          style: TextStyle(
                            color: Color(0xFFE39A7B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Deadline: ${internship.deadline.toString().split(' ')[0]}',
                          style: TextStyle(
                            color: Color(0xFFE39A7B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Color(0xFFE39A7B)),
                      onPressed: () => _showDeleteInternshipDialog(internship),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApplicationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('applications').snapshots(),
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
                  color: Color(0xFFE39A7B).withAlpha(128),
                ),
                SizedBox(height: 10),
                Text(
                  'No applications yet',
                  style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                ),
              ],
            ),
          );
        }

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
                        color: Color(0xFFE39A7B).withAlpha(26),
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
                              'Student Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFE39A7B),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Name: ${applicationData['studentName'] ?? 'Unknown Student'}',
                              style: TextStyle(color: Color(0xFF4A4A4A)),
                            ),
                            Text(
                              'Email: ${applicationData['studentEmail'] ?? 'Not provided'}',
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

  void _showDeleteUserDialog(UserModel user) {
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
                          color: Color(0xFFE39A7B).withAlpha(12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning,
                          color: Color(0xFFE39A7B),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete User',
                        style: TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Are you sure you want to delete ${user.name}? This action cannot be undone.',
                    style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                    textAlign: TextAlign.center,
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
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteUser(user.uid);
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
                          'Delete',
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

  void _showDeleteInternshipDialog(Internship internship) {
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
                          color: Color(0xFFE39A7B).withAlpha(12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning,
                          color: Color(0xFFE39A7B),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete Internship',
                        style: TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Are you sure you want to delete "${internship.title}"? This action cannot be undone.',
                    style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 16),
                    textAlign: TextAlign.center,
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
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteInternship(internship.id);
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
                          'Delete',
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
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFFFF5F0),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF4A4A4A)),
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _currentIndex = index),
          indicatorColor: Color(0xFFE39A7B),
          labelColor: Color(0xFFE39A7B),
          unselectedLabelColor: Color(0xFF4A4A4A).withAlpha(128),
          tabs: [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.work), text: 'Internships'),
            Tab(icon: Icon(Icons.description), text: 'Applications'),
          ],
        ),
      ),
      body: ScrollConfiguration(
        behavior: ScrollBehavior().copyWith(
          physics: BouncingScrollPhysics(),
          scrollbars: false,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersSection(),
            _buildInternshipsSection(),
            _buildApplicationsSection(),
          ],
        ),
      ),
    );
  }
}
