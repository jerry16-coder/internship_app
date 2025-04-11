import 'package:cloud_firestore/cloud_firestore.dart';

class Internship {
  final String id;
  final String title;
  final String description;
  final String companyName;
  final String location;
  final String duration;
  final double stipend;
  final String requirements;
  final String skills;
  final DateTime deadline;
  final String employerId;
  final DateTime createdAt;
  final List<String> applications;

  Internship({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.location,
    required this.duration,
    required this.stipend,
    required this.requirements,
    required this.skills,
    required this.deadline,
    required this.employerId,
    required this.createdAt,
    this.applications = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'companyName': companyName,
      'location': location,
      'duration': duration,
      'stipend': stipend,
      'requirements': requirements,
      'skills': skills,
      'deadline': Timestamp.fromDate(deadline),
      'employerId': employerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'applications': applications,
    };
  }

  factory Internship.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Internship(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      companyName: data['companyName'] ?? '',
      location: data['location'] ?? '',
      duration: data['duration'] ?? '',
      stipend: (data['stipend'] ?? 0.0).toDouble(),
      requirements: data['requirements'] ?? '',
      skills: data['skills'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      employerId: data['employerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      applications: List<String>.from(data['applications'] ?? []),
    );
  }
}
