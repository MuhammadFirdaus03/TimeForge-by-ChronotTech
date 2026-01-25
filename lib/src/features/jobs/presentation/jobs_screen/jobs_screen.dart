import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/strings.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/data/jobs_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/presentation/jobs_screen/jobs_screen_controller.dart';
import 'package:starter_architecture_flutter_firebase/src/routing/app_router.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/async_value_ui.dart';
import 'package:starter_architecture_flutter_firebase/src/features/timer/presentation/timer_controller.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Strings.jobs,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () => context.goNamed(AppRoute.addJob.name),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'ACTIVE'),
                Tab(text: 'ARCHIVED'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          ref.listen<AsyncValue>(
            jobsScreenControllerProvider,
            (_, state) => state.showAlertDialogOnError(context),
          );
          
          final timerState = ref.watch(timerControllerProvider);

          return TabBarView(
            controller: _tabController,
            children: [
              JobsListView(
                showArchived: false,
                activeJobId: timerState.activeJob?.id,
              ),
              JobsListView(
                showArchived: true,
                activeJobId: timerState.activeJob?.id,
              ),
            ],
          );
        },
      ),
    );
  }
}

class JobsListView extends ConsumerWidget {
  const JobsListView({
    super.key, 
    required this.showArchived,
    this.activeJobId,
  });
  
  final bool showArchived;
  final String? activeJobId;

  // Dialog to ask for the task name before starting the timer
  Future<String?> _showTaskNameDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('New Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'What are you working on?',
            hintText: 'e.g., Backend, UI Design, Research',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // --- NEW: Double-layer verification dialog for deletion ---
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Job job) async {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Delete ${job.name}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action is permanent and cannot be undone. All entries for this job will be lost.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                Text('Please type "${job.name}" to confirm:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: job.name,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}), // Refresh to update button state
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: controller.text == job.name
                    ? () => Navigator.pop(context, true)
                    : null, // Disabled until names match
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
    final jobsQuery = ref.watch(jobsQueryProvider);
    
    return FirestoreListView<Job>(
      query: jobsQuery,
      emptyBuilder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showArchived ? Icons.archive_outlined : Icons.work_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              showArchived ? 'No archived jobs' : 'No active jobs',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showArchived 
                  ? 'Archived jobs will appear here'
                  : 'Tap + to create your first job',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(color: Colors.red[700], fontSize: 16),
            ),
          ],
        ),
      ),
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, doc) {
        final job = doc.data();
        
        final isArchived = job.status == JobStatus.archived;
        if (isArchived != showArchived) {
          return const SizedBox.shrink();
        }
        
        return Dismissible(
          key: Key('job-${job.id}'),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 32),
          ),
          direction: DismissDirection.endToStart,
          // --- UPDATED: Use confirmDismiss for double-layer verification ---
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmationDialog(context, job);
          },
          onDismissed: (direction) => ref
              .read(jobsScreenControllerProvider.notifier)
              .deleteJob(job),
          child: JobCard(
            job: job,
            isTracking: job.id == activeJobId,
            onTap: () => context.goNamed(
              AppRoute.job.name,
              pathParameters: {'id': job.id},
            ),
            onStartTimer: () async {
              // Ensure we only start a timer if the job is paid
              if (job.pricingType != JobPricingType.unpaid || job.pricingType == JobPricingType.hourly) {
                  // Wait for the user to provide a name for the entry
                  final name = await _showTaskNameDialog(context);
                  
                  if (name != null && name.isNotEmpty) {
                    ref.read(timerControllerProvider.notifier).startTimer(job, name);
                  }
              } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot track time for unpaid jobs'))
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key, 
    required this.job, 
    this.onTap,
    this.onStartTimer,
    this.isTracking = false,
  });
  
  final Job job;
  final VoidCallback? onTap;
  final VoidCallback? onStartTimer;
  final bool isTracking;

  List<Color> _getGradient() {
    final hash = job.name.hashCode;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], 
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], 
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], 
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], 
      [const Color(0xFFfa709a), const Color(0xFFfee140)], 
      [const Color(0xFF30cfd0), const Color(0xFF330867)], 
    ];
    return gradients[hash.abs() % gradients.length];
  }

  IconData _getIcon() {
    final name = job.name.toLowerCase();
    if (name.contains('design') || name.contains('art')) return Icons.palette;
    if (name.contains('code') || name.contains('dev')) return Icons.code;
    if (name.contains('write') || name.contains('blog')) return Icons.edit;
    if (name.contains('teach') || name.contains('tutor')) return Icons.school;
    if (name.contains('consult')) return Icons.business_center;
    if (name.contains('market')) return Icons.trending_up;
    return Icons.work;
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = job.status == JobStatus.archived;
    final gradient = _getGradient();
    final icon = _getIcon();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isArchived 
            ? LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[500]!],
              )
            : LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isArchived 
                ? Colors.grey.withOpacity(0.3)
                : gradient[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (job.clientCompany?.isNotEmpty == true || job.clientName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.clientCompany?.isNotEmpty == true 
                                    ? job.clientCompany! 
                                    : job.clientName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.white70,
                            size: 16,
                          ),
                          Text(
                            job.getDisplayPrice(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isArchived) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ARCHIVED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isArchived && !isTracking)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.play_arrow, color: gradient[0]),
                      onPressed: onStartTimer,
                      tooltip: 'Start Timer',
                    ),
                  ),
                if (isTracking)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                if (isArchived)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}