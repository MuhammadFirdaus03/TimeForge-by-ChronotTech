import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/data/entries_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/domain/entry.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/presentation/job_entries_screen/entry_list_item.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/presentation/job_entries_screen/job_entries_list_controller.dart';
import 'package:starter_architecture_flutter_firebase/src/routing/app_router.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/async_value_ui.dart';

class JobEntriesList extends ConsumerWidget {
  const JobEntriesList({super.key, required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue>(
      jobsEntriesListControllerProvider,
      (_, state) => state.showAlertDialogOnError(context),
    );
    final jobEntriesQuery = ref.watch(jobEntriesQueryProvider(job.id));
    return FirestoreListView<Entry>(
      query: jobEntriesQuery,
      itemBuilder: (context, doc) {
        final entry = doc.data();
        return DismissibleEntryListItem(
          dismissibleKey: Key('entry-${entry.id}'),
          entry: entry,
          job: job,
          onDismissed: () => ref
              .read(jobsEntriesListControllerProvider.notifier)
              .deleteEntry(entry.id),
          onTap: () => context.goNamed(
            AppRoute.entry.name,
            pathParameters: {'id': job.id, 'eid': entry.id},
            extra: entry,
          ),
        );
      },
    );
  }
}

class DismissibleEntryListItem extends ConsumerWidget {
  const DismissibleEntryListItem({
    super.key,
    required this.dismissibleKey,
    required this.entry,
    required this.job,
    required this.onDismissed,
    required this.onTap,
  });

  final Key dismissibleKey;
  final Entry entry;
  final Job job;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  // --- Double-layer verification dialog for entries ---
  Future<bool?> _showDeleteEntryDialog(BuildContext context) async {
    final controller = TextEditingController();
    const confirmationWord = 'DELETE';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Time Entry?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action is permanent and will remove this time log from your records.',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text('Please type "DELETE" to confirm:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: confirmationWord,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: controller.text == confirmationWord
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: dismissibleKey,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      // --- Integrated Verification ---
      confirmDismiss: (direction) async {
        return await _showDeleteEntryDialog(context);
      },
      onDismissed: (direction) => onDismissed(),
      child: EntryListItem(
        entry: entry,
        job: job,
        onTap: onTap,
      ),
    );
  }
}