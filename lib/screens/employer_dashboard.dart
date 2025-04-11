import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/internship_model.dart';
import '../models/user_model.dart';

class EmployerDashboard extends StatefulWidget {
  @override
  _EmployerDashboardState createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;
  int _currentIndex = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _stipendController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(Duration(days: 30));
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
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _stipendController.dispose();
    _requirementsController.dispose();
    _skillsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
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

  Future<void> _createInternship() async {
    try {
      // Validate required fields
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _companyNameController.text.trim().isEmpty ||
          _locationController.text.trim().isEmpty ||
          _durationController.text.trim().isEmpty ||
          _stipendController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double stipend;
      try {
        String stipendText = _stipendController.text.trim();
        if (!RegExp(r'^\d*\.?\d+$').hasMatch(stipendText)) {
          throw FormatException(
            'Please enter a valid amount (e.g., 5000 or 5000.50)',
          );
        }
        stipend = double.parse(stipendText);
        if (stipend < 0) {
          throw FormatException('Stipend amount cannot be negative');
        }
        if (stipend > 1000000) {
          throw FormatException(
            'Stipend amount seems too high. Please verify the amount',
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      String uid = _auth.currentUser!.uid;
      await _firestore.collection('internships').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'location': _locationController.text.trim(),
        'duration': _durationController.text.trim(),
        'stipend': stipend,
        'requirements': _requirementsController.text.trim(),
        'skills': _skillsController.text.trim(),
        'deadline': Timestamp.fromDate(_selectedDeadline),
        'employerId': uid,
        'createdAt': Timestamp.now(),
        'applications': [],
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _companyNameController.clear();
      _locationController.clear();
      _durationController.clear();
      _stipendController.clear();
      _requirementsController.clear();
      _skillsController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Internship posted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting internship: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      var applicationDoc =
          await _firestore.collection('applications').doc(applicationId).get();
      var application = applicationDoc.data()!;

      await _firestore.collection('applications').doc(applicationId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      if (status == 'Rejected') {
        await _firestore
            .collection('internships')
            .doc(application['internshipId'])
            .update({
              'applications': FieldValue.arrayRemove([
                application['studentId'],
              ]),
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating application status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteInternship(String internshipId) async {
    try {
      await _firestore.collection('internships').doc(internshipId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Internship deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting internship'),
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
                          Icons.business,
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
                    icon: Icons.business,
                    title: 'Role',
                    value: _user?.role ?? 'Employer',
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
                          color: Color(0xFFE39A7B).withAlpha(26),
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
                          color: Color(0xFFE39A7B).withAlpha(26),
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
                                color: Color(0xFFE39A7B).withAlpha(26),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withAlpha(26),
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
                                color: Color(0xFFE39A7B).withAlpha(26),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE39A7B).withAlpha(26),
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
        color: Color(0xFFFFF5F0).withAlpha(204),
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

  Widget _buildPostInternshipSection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Post New Internship',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _titleController,
            label: 'Internship Title',
            icon: Icons.title,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _companyNameController,
            label: 'Company Name',
            icon: Icons.business,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _durationController,
            label: 'Duration',
            icon: Icons.calendar_today,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _stipendController,
            label: 'Stipend',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description,
            maxLines: 3,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _requirementsController,
            label: 'Requirements',
            icon: Icons.list,
            maxLines: 3,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _skillsController,
            label: 'Required Skills',
            icon: Icons.code,
            maxLines: 2,
          ),
          SizedBox(height: 15),
          ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.blue[800]),
            title: Text('Application Deadline'),
            subtitle: Text(
              '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDeadline = picked;
                  });
                }
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createInternship,
            child: Text(
              'Post Internship',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE39A7B),
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildInternshipsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('internships')
              .where('employerId', isEqualTo: _auth.currentUser!.uid)
              .snapshots(),
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
                  'No internships posted yet',
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
            var internship = Internship.fromFirestore(internships[index]);
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(26),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(15),
                title: Text(
                  internship.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship.companyName),
                    Text(internship.location),
                    SizedBox(height: 10),
                    Text(
                      'Applications: ${internship.applications.length}',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                    Text(
                      'Deadline: ${internship.deadline.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(child: Text('Edit'), value: 'edit'),
                        PopupMenuItem(child: Text('Delete'), value: 'delete'),
                      ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteInternship(internship.id);
                    }
                  },
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
      stream:
          _firestore
              .collection('applications')
              .where('employerId', isEqualTo: _auth.currentUser!.uid)
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
                            SizedBox(height: 15),
                            if (applicationData['status'] == 'Pending')
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => _updateApplicationStatus(
                                          application.id,
                                          'Approved',
                                        ),
                                    child: Text(
                                      'Approve',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      elevation: 0,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => _updateApplicationStatus(
                                          application.id,
                                          'Rejected',
                                        ),
                                    child: Text(
                                      'Reject',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            if (applicationData['status'] == 'Approved')
                              ElevatedButton(
                                onPressed:
                                    () => _updateApplicationStatus(
                                      application.id,
                                      'Completed',
                                    ),
                                child: Text(
                                  'Mark as Completed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  elevation: 0,
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
      case 'completed':
        return Colors.purple;
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
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          _buildInternshipsSection(),
                          _buildPostInternshipSection(),
                          _buildApplicationsSection(),
                        ],
                      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'My Internships',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Post New',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Applications',
          ),
        ],
      ),
    );
  }
}
