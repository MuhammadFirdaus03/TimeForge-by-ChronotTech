import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/strings.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entries_list_tile_model.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/application/entries_service.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/list_items_builder.dart';

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  String _getFilterText(EntriesFilterState state) {
    switch (state.type) {
      case EntriesFilterType.last7Days:
        return 'Last 7 Days';
      case EntriesFilterType.last30Days:
        return 'Last 30 Days';
      case EntriesFilterType.last3Months:
        return 'Last 3 Months';
      case EntriesFilterType.last6Months:
        return 'Last 6 Months';
      case EntriesFilterType.allTime:
        return 'All Time';
      case EntriesFilterType.custom:
        if (state.customRange != null) {
          final start = DateFormat('MMM d').format(state.customRange!.start);
          final end = DateFormat('MMM d').format(state.customRange!.end);
          return '$start - $end';
        }
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(entriesFilterProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withBlue(255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              Strings.entries,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PopupMenuButton<EntriesFilterType>(
                  initialValue: filterState.type,
                  icon: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Filter Dates',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (type) async {
                    if (type == EntriesFilterType.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        ref.read(entriesFilterProvider.notifier).setCustomRange(picked);
                      }
                    } else {
                      ref.read(entriesFilterProvider.notifier).setFilter(type);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: EntriesFilterType.last7Days,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_view_week, size: 18),
                          SizedBox(width: 8),
                          Text('Last 7 Days'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: EntriesFilterType.last30Days,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_view_month, size: 18),
                          SizedBox(width: 8),
                          Text('Last 30 Days'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: EntriesFilterType.last3Months,
                      child: Row(
                        children: [
                          Icon(Icons.event_note, size: 18),
                          SizedBox(width: 8),
                          Text('Last 3 Months'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: EntriesFilterType.last6Months,
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 18),
                          SizedBox(width: 8),
                          Text('Last 6 Months'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: EntriesFilterType.allTime,
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, size: 18),
                          SizedBox(width: 8),
                          Text('All Time'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: EntriesFilterType.custom,
                      child: Row(
                        children: [
                          Icon(Icons.date_range, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Custom Range...', style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _getFilterText(filterState),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final entriesTileModelStream = ref.watch(entriesTileModelStreamProvider);
          return ListItemsBuilder<EntriesListTileModel>(
            data: entriesTileModelStream,
            itemBuilder: (context, model) => ModernEntriesListTile(model: model),
          );
        },
      ),
    );
  }
}

class ModernEntriesListTile extends StatelessWidget {
  const ModernEntriesListTile({super.key, required this.model});
  final EntriesListTileModel model;

  @override
  Widget build(BuildContext context) {
    if (model.leadingText == 'All Entries') {
      // Summary card at the top
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withBlue(255),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.summarize,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Hourly Earnings',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.middleText ?? '\$0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Fixed & unpaid tracked separately',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(height: 4),
                Text(
                  model.trailingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'All jobs',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (model.isHeader) {
      // Date header card
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo[400]!,
              Colors.indigo[600]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model.leadingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (model.middleText != null && model.middleText!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  model.middleText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              model.trailingText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Individual entry card - FIXED to properly handle payment types
    // The middleText comes from JobDetails.getPaymentDisplay()
    final paymentText = model.middleText ?? '';
    final isUnpaid = paymentText == 'Unpaid';
    final isFixed = paymentText.startsWith('Fixed:');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnpaid 
                    ? [Colors.grey[400]!, Colors.grey[600]!]
                    : isFixed
                        ? [Colors.purple[400]!, Colors.purple[600]!]
                        : [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUnpaid 
                  ? Icons.volunteer_activism
                  : isFixed
                      ? Icons.check_circle
                      : Icons.attach_money,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.leadingText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (isUnpaid) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unpaid / Portfolio Work',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (isFixed) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Fixed price project',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (paymentText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isUnpaid 
                    ? Colors.grey[100]
                    : isFixed 
                        ? Colors.purple[50] 
                        : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnpaid
                      ? Colors.grey[300]!
                      : isFixed 
                          ? Colors.purple[200]! 
                          : Colors.green[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFixed)
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Colors.purple[700],
                    ),
                  if (isFixed) const SizedBox(width: 4),
                  if (isUnpaid)
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  if (isUnpaid) const SizedBox(width: 4),
                  Text(
                    paymentText,
                    style: TextStyle(
                      color: isUnpaid
                          ? Colors.grey[700]
                          : isFixed 
                              ? Colors.purple[800] 
                              : Colors.green[800],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  model.trailingText,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}