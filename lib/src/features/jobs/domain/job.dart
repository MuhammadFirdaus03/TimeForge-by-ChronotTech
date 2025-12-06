import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';

typedef JobID = String;

// Job status
enum JobStatus {
  active,
  archived,
}

// NEW: Pricing types
enum JobPricingType {
  hourly,      // Charge by the hour
  fixedPrice,  // One-time fixed amount
  unpaid,      // Free work / Portfolio
}

@immutable
class Job extends Equatable {
  const Job({
    required this.id,
    required this.name,
    this.clientId = '',  // Empty default for backward compatibility
    this.pricingType = JobPricingType.hourly,
    this.ratePerHour,
    this.fixedPrice,
    this.status = JobStatus.active,
    // Keep old client fields for backward compatibility during migration
    this.clientName = '',
    this.clientEmail,
    this.clientCompany,
    this.clientPhone,
  });
  
  final JobID id;
  final String name;
  final ClientID clientId;              // NEW: Link to client
  final JobPricingType pricingType;     // NEW: How you charge
  final int? ratePerHour;               // For hourly jobs
  final double? fixedPrice;             // NEW: For fixed-price jobs
  final JobStatus status;
  
  // OLD: Keep these for backward compatibility (will be removed after migration)
  final String clientName;
  final String? clientEmail;
  final String? clientCompany;
  final String? clientPhone;

  @override
  List<Object?> get props => [
    name, 
    clientId,
    pricingType,
    ratePerHour,
    fixedPrice,
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
    
    // Read client ID (default to empty for old jobs)
    final clientId = data['clientId'] as String? ?? '';
    
    // Read pricing type (default to hourly for old jobs)
    final pricingTypeString = data['pricingType'] as String?;
    final pricingType = pricingTypeString != null
        ? JobPricingType.values.firstWhere(
            (e) => e.name == pricingTypeString,
            orElse: () => JobPricingType.hourly,
          )
        : JobPricingType.hourly;
    
    // Read pricing values
    final ratePerHour = data['ratePerHour'] as int?;
    final fixedPrice = (data['fixedPrice'] as num?)?.toDouble();
    
    // Read status
    final statusString = data['status'] as String?;
    final status = statusString == 'archived' 
        ? JobStatus.archived 
        : JobStatus.active;
    
    // Read old client fields (for backward compatibility)
    final clientName = data['clientName'] as String? ?? '';
    final clientEmail = data['clientEmail'] as String?;
    final clientCompany = data['clientCompany'] as String?;
    final clientPhone = data['clientPhone'] as String?;
    
    return Job(
      id: id,
      name: name,
      clientId: clientId,
      pricingType: pricingType,
      ratePerHour: ratePerHour,
      fixedPrice: fixedPrice,
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
      'clientId': clientId,
      'pricingType': pricingType.name,
      if (ratePerHour != null) 'ratePerHour': ratePerHour,
      if (fixedPrice != null) 'fixedPrice': fixedPrice,
      'status': status == JobStatus.archived ? 'archived' : 'active',
      // Keep old fields for backward compatibility
      'clientName': clientName,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (clientCompany != null) 'clientCompany': clientCompany,
      if (clientPhone != null) 'clientPhone': clientPhone,
    };
  }
  
  Job copyWith({
    String? name,
    ClientID? clientId,
    JobPricingType? pricingType,
    int? ratePerHour,
    double? fixedPrice,
    JobStatus? status,
    String? clientName,
    String? clientEmail,
    String? clientCompany,
    String? clientPhone,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      pricingType: pricingType ?? this.pricingType,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientCompany: clientCompany ?? this.clientCompany,
      clientPhone: clientPhone ?? this.clientPhone,
    );
  }
  
  // Helper: Get display price
  String getDisplayPrice() {
    switch (pricingType) {
      case JobPricingType.hourly:
        return '\$${ratePerHour ?? 0}/hr';
      case JobPricingType.fixedPrice:
        return '\$${fixedPrice?.toStringAsFixed(0) ?? "0"}';
      case JobPricingType.unpaid:
        return 'Unpaid';
    }
  }
  
  // Helper: Calculate earnings for time tracked
  double calculateEarnings(double hours) {
    switch (pricingType) {
      case JobPricingType.hourly:
        return hours * (ratePerHour ?? 0);
      case JobPricingType.fixedPrice:
        return fixedPrice ?? 0.0;
      case JobPricingType.unpaid:
        return 0.0;
    }
  }
}