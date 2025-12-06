import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef ClientID = String;

@immutable
class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.company,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.createdAt,
  });
  
  final ClientID id;
  final String name;           // Contact person name (e.g., "John Smith")
  final String company;        // Company name (e.g., "Acme Corp")
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    name,
    company,
    email,
    phone,
    address,
    notes,
    createdAt,
  ];

  @override
  bool get stringify => true;

  // Create from Firestore
  factory Client.fromMap(Map<String, dynamic> data, String id) {
    return Client(
      id: id,
      name: data['name'] as String? ?? '',
      company: data['company'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
    };
  }
  
  // Helper to create a copy with changes
  Client copyWith({
    String? name,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? notes,
    DateTime? createdAt,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Display name for UI (Company is primary, name is secondary)
  String get displayName => company.isNotEmpty ? company : name;
  
  // Full name with both (for detailed views)
  String get fullDisplayName {
    if (company.isNotEmpty && name.isNotEmpty) {
      return '$company ($name)';
    }
    return displayName;
  }
}