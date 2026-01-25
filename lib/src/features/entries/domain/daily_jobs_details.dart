
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entry_job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';

/// Temporary model class to store the time tracked and pay for a job
class JobDetails {
  JobDetails({
    required this.name,
    required this.durationInHours,
    required this.pay,
    this.pricingType,
    this.fixedPrice,
  });
  final String name;
  double durationInHours;
  double pay;
  final JobPricingType? pricingType;
  final double? fixedPrice;
  
  // Helper to get display string for payment
  String getPaymentDisplay() {
    if (pricingType == JobPricingType.unpaid) {
      return 'Unpaid';
    } else if (pricingType == JobPricingType.fixedPrice && fixedPrice != null) {
      return 'Fixed: \$${fixedPrice!.toStringAsFixed(0)}';
    } else {
      // Hourly - show actual earnings
      return pay > 0 ? '\$${pay.toStringAsFixed(2)}' : '\$0.00';
    }
  }
}

/// Groups together all jobs/entries on a given day
class DailyJobsDetails {
  DailyJobsDetails({required this.date, required this.jobsDetails});
  final DateTime date;
  final List<JobDetails> jobsDetails;

  // Only sum hourly jobs for pay
  double get pay => jobsDetails
      .where((job) => job.pricingType == JobPricingType.hourly)
      .map((jobDuration) => jobDuration.pay)
      .fold(0.0, (sum, pay) => sum + pay);

  double get duration => jobsDetails
      .map((jobDuration) => jobDuration.durationInHours)
      .reduce((value, element) => value + element);

  /// splits all entries into separate groups by date
  static Map<DateTime, List<EntryJob>> _entriesByDate(List<EntryJob> entries) {
    final Map<DateTime, List<EntryJob>> map = {};
    for (final entryJob in entries) {
      final entryDayStart = DateTime(entryJob.entry.start.year,
          entryJob.entry.start.month, entryJob.entry.start.day);
      if (map[entryDayStart] == null) {
        map[entryDayStart] = [entryJob];
      } else {
        map[entryDayStart]!.add(entryJob);
      }
    }
    return map;
  }

  /// maps an unordered list of EntryJob into a list of DailyJobsDetails with date information
  static List<DailyJobsDetails> all(List<EntryJob> entries) {
    final byDate = _entriesByDate(entries);
    final List<DailyJobsDetails> list = [];
    for (final pair in byDate.entries) {
      final date = pair.key;
      final entriesByDate = pair.value;
      final byJob = _jobsDetails(entriesByDate);
      list.add(DailyJobsDetails(date: date, jobsDetails: byJob));
    }
    
    // Sort by date, newest first (descending)
    list.sort((a, b) => b.date.compareTo(a.date));
    
    return list;
  }

  /// groups entries by job
  static List<JobDetails> _jobsDetails(List<EntryJob> entries) {
    final Map<String, JobDetails> jobDuration = {};
    for (final entryJob in entries) {
      final entry = entryJob.entry;
      final job = entryJob.job;
      
      // Calculate pay (0.0 for fixed/unpaid)
      final pay = job.calculateEarnings(entry.durationInHours);
      
      if (jobDuration[entry.jobId] == null) {
        jobDuration[entry.jobId] = JobDetails(
          name: job.name,
          durationInHours: entry.durationInHours,
          pay: pay,
          pricingType: job.pricingType,
          fixedPrice: job.fixedPrice, 
        );
      } else {
        
        jobDuration[entry.jobId]!.pay += pay;
        jobDuration[entry.jobId]!.durationInHours += entry.durationInHours;
      }
    }
    return jobDuration.values.toList();
  }
} 
