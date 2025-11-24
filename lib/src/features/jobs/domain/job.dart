import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef JobID = String;

// ADDED: Enum for job status
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
    this.status = JobStatus.active, // ADDED: Default to active
  });
  
  final JobID id;
  final String name;
  final int ratePerHour;
  final JobStatus status; // ADDED: Status field

  @override
  List<Object> get props => [name, ratePerHour, status]; // ADDED: status to props

  @override
  bool get stringify => true;

  factory Job.fromMap(Map<String, dynamic> data, String id) {
    final name = data['name'] as String;
    final ratePerHour = data['ratePerHour'] as int;
    // ADDED: Read status from Firebase, default to active if not present
    final statusString = data['status'] as String?;
    final status = statusString == 'archived' 
        ? JobStatus.archived 
        : JobStatus.active;
    
    return Job(
      id: id,
      name: name,
      ratePerHour: ratePerHour,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ratePerHour': ratePerHour,
      'status': status == JobStatus.archived ? 'archived' : 'active', // ADDED: Save status
    };
  }
  
  // ADDED: Helper method to create a copy with different status
  Job copyWith({
    String? name,
    int? ratePerHour,
    JobStatus? status,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      status: status ?? this.status,
    );
  }
}