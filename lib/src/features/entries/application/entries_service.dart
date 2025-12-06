import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/domain/app_user.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/data/entries_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/daily_jobs_details.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entries_list_tile_model.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entry_job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/data/jobs_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/format.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entry.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';
import 'package:intl/intl.dart'; 

part 'entries_service.g.dart';

// ==========================================
// 1. FILTER LOGIC
// ==========================================

enum EntriesFilterType {
  last7Days,
  last30Days,
  last3Months,
  last6Months,
  allTime,
  custom,
}

class EntriesFilterState {
  final EntriesFilterType type;
  final DateTimeRange? customRange;

  EntriesFilterState({this.type = EntriesFilterType.allTime, this.customRange});
}

@riverpod
class EntriesFilter extends _$EntriesFilter {
  @override
  EntriesFilterState build() {
    return EntriesFilterState(); 
  }

  void setFilter(EntriesFilterType type) {
    state = EntriesFilterState(type: type);
  }

  void setCustomRange(DateTimeRange range) {
    state = EntriesFilterState(
      type: EntriesFilterType.custom,
      customRange: range,
    );
  }
}

// ==========================================
// 2. SERVICE CLASS
// ==========================================

class EntriesService {
  EntriesService(
      {required this.jobsRepository, required this.entriesRepository});
  final JobsRepository jobsRepository;
  final EntriesRepository entriesRepository;

  /// combine List<Job>, List<Entry> into List<EntryJob>
  Stream<List<EntryJob>> _allEntriesStream(UserID uid) =>
      CombineLatestStream.combine2(
        entriesRepository.watchEntries(uid: uid),
        jobsRepository.watchJobs(uid: uid),
        _entriesJobsCombiner,
      );

  static List<EntryJob> _entriesJobsCombiner(
      List<Entry> entries, List<Job> jobs) {
    return entries.map((entry) {
      try {
        final job = jobs.firstWhere((job) => job.id == entry.jobId);
        return EntryJob(entry, job);
      } catch (e) {
        return null;
      }
    }).whereType<EntryJob>().toList();
  }

  Future<String> exportEntriesToCsv(UserID uid, EntriesFilterState filterState) async {
    final allEntries = await _allEntriesStream(uid).first;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    DateTime? startFilter;
    DateTime? endFilter;

    switch (filterState.type) {
      case EntriesFilterType.last7Days:
        startFilter = endOfToday.subtract(const Duration(days: 7)); break;
      case EntriesFilterType.last30Days:
        startFilter = endOfToday.subtract(const Duration(days: 30)); break;
      case EntriesFilterType.last3Months:
        startFilter = endOfToday.subtract(const Duration(days: 90)); break;
      case EntriesFilterType.last6Months:
        startFilter = endOfToday.subtract(const Duration(days: 180)); break;
      case EntriesFilterType.allTime:
        startFilter = null; break;
      case EntriesFilterType.custom:
        startFilter = filterState.customRange?.start;
        endFilter = filterState.customRange?.end != null 
              ? filterState.customRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)) 
              : null;
        break;
    }

    final filteredEntries = allEntries.where((entryJob) {
        final entryDate = entryJob.entry.start;
        if (entryJob.job.status == JobStatus.archived) return false;
        if (startFilter != null && entryDate.isBefore(startFilter)) return false;
        if (endFilter != null && entryDate.isAfter(endFilter)) return false;
        return true;
    }).toList();

    final List<List<String>> rawRows = [];
    rawRows.add(['Date', 'Job Name', 'Start Time', 'End Time', 'Duration (Hours)', 'Rate (\$)', 'Earnings (\$)']);

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm:ss');

    for (final entryJob in filteredEntries) {
        final entry = entryJob.entry;
        final job = entryJob.job;
        
        final duration = entry.end.difference(entry.start);
        final durationInHours = duration.inMinutes / 60;
        final pay = durationInHours * job.ratePerHour;

        rawRows.add([
            dateFormatter.format(entry.start),
            job.name,
            timeFormatter.format(entry.start), 
            timeFormatter.format(entry.end),   
            durationInHours.toStringAsFixed(2),
            job.ratePerHour.toString(),
            pay.toStringAsFixed(2),
        ]);
    }
    
    final csv = rawRows.map((row) => row.join(',')).join('\n');
    return csv;
  }
  
  Stream<List<EntriesListTileModel>> entriesTileModelStream(
    UserID uid, {
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _allEntriesStream(uid).map((entries) {
        entries = entries.where((entryJob) {
          final entryDate = entryJob.entry.start;
          
          if (entryJob.job.status == JobStatus.archived) {
             return false;
          }
          
          if (startDate != null && entryDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && entryDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
        
        return _createModels(entries);
      });

  static List<EntriesListTileModel> _createModels(List<EntryJob> allEntries) {
    if (allEntries.isEmpty) {
      return [];
    }
    
    // CHANGED: Create mutable list and sort properly
    final allDailyJobsDetails = List<DailyJobsDetails>.from(
      DailyJobsDetails.all(allEntries)
    )..sort((a, b) {
      // Sort by date descending (newest first)
      return b.date.compareTo(a.date);
    });

    final totalDuration = allDailyJobsDetails
        .map((dateJobsDuration) => dateJobsDuration.duration)
        .reduce((value, element) => value + element);

    final totalPay = allDailyJobsDetails
        .map((dateJobsDuration) => dateJobsDuration.pay)
        .reduce((value, element) => value + element);

    return <EntriesListTileModel>[
      EntriesListTileModel(
        leadingText: 'All Entries',
        middleText: Format.currency(totalPay),
        trailingText: Format.hours(totalDuration),
      ),
      for (DailyJobsDetails dailyJobsDetails in allDailyJobsDetails) ...[
        EntriesListTileModel(
          isHeader: true,
          leadingText: Format.date(dailyJobsDetails.date),
          middleText: Format.currency(dailyJobsDetails.pay),
          trailingText: Format.hours(dailyJobsDetails.duration),
        ),
        for (JobDetails jobDuration in dailyJobsDetails.jobsDetails)
          EntriesListTileModel(
            leadingText: jobDuration.name,
            middleText: Format.currency(jobDuration.pay),
            trailingText: Format.hours(jobDuration.durationInHours),
          ),
      ]
    ];
  }
}

@riverpod
EntriesService entriesService(Ref ref) {
  return EntriesService(
    jobsRepository: ref.watch(jobsRepositoryProvider),
    entriesRepository: ref.watch(entriesRepositoryProvider),
  );
}

@riverpod
Stream<List<EntriesListTileModel>> entriesTileModelStream(Ref ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw AssertionError('User can\'t be null when fetching entries');
  }
  
  final entriesService = ref.watch(entriesServiceProvider);
  final filterState = ref.watch(entriesFilterProvider);

  DateTime? start;
  DateTime? end;


  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filterState.type) {
    case EntriesFilterType.last7Days:
      start = endOfToday.subtract(const Duration(days: 7));
      break;
    case EntriesFilterType.last30Days:
      start = endOfToday.subtract(const Duration(days: 30));
      break;
    case EntriesFilterType.last3Months:
      start = endOfToday.subtract(const Duration(days: 90));
      break;
    case EntriesFilterType.last6Months:
      start = endOfToday.subtract(const Duration(days: 180));
      break;
    case EntriesFilterType.allTime:
      start = null;
      break;
    case EntriesFilterType.custom:
      start = filterState.customRange?.start;
      end = filterState.customRange?.end != null 
            ? filterState.customRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)) 
            : null;
      break;
  }

  return entriesService.entriesTileModelStream(
    user.uid, 
    startDate: start, 
    endDate: end
  );
}