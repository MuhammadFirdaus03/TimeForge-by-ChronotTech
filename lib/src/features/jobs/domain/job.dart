import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef JobID = String;

// Enum for job status
enum JobStatus {
  active,
  archived,
}

@immutable
class Job extends Equatable {
  const Job({
    required this.id,
    required this.name,
    required this.ratePerHour,
    this.status = JobStatus.active,
    // NEW: Client information fields for invoicing
    this.clientName = '',
    this.clientEmail,
    this.clientCompany,
    this.clientPhone,
  });
  
  final JobID id;
  final String name;
  final int ratePerHour;
  final JobStatus status;
  
  // NEW: Client information for invoicing
  final String clientName;
  final String? clientEmail;
  final String? clientCompany;
  final String? clientPhone;

  @override
  List<Object?> get props => [
    name, 
    ratePerHour, 
    status,
    clientName,
    clientEmail,
    clientCompany,
    clientPhone,
  ];

  @override
  bool get stringify => true;

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    final name = data['name'] as String;
    final ratePerHour = data['ratePerHour'] as int;
    
    // Read status from Firebase, default to active if not present
    final statusString = data['status'] as String?;
    final status = statusString == 'archived' 
        ? JobStatus.archived 
        : JobStatus.active;
    
    // NEW: Read client information from Firebase
    final clientName = data['clientName'] as String? ?? '';
    final clientEmail = data['clientEmail'] as String?;
    final clientCompany = data['clientCompany'] as String?;
    final clientPhone = data['clientPhone'] as String?;
    
    return Job(
      id: id,
      name: name,
      ratePerHour: ratePerHour,
      status: status,
      clientName: clientName,
      clientEmail: clientEmail,
      clientCompany: clientCompany,
      clientPhone: clientPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ratePerHour': ratePerHour,
      'status': status == JobStatus.archived ? 'archived' : 'active',
      // NEW: Save client information to Firebase
      'clientName': clientName,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (clientCompany != null) 'clientCompany': clientCompany,
      if (clientPhone != null) 'clientPhone': clientPhone,
    };
  }
  
  // Helper method to create a copy with different values
  Job copyWith({
    String? name,
    int? ratePerHour,
    JobStatus? status,
    String? clientName,
    String? clientEmail,
    String? clientCompany,
    String? clientPhone,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientCompany: clientCompany ?? this.clientCompany,
      clientPhone: clientPhone ?? this.clientPhone,
    );
  }
}