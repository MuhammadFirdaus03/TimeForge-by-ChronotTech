import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/async_value_widget.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/data/jobs_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/presentation/job_entries_screen/job_entries_list.dart';
import 'package:starter_architecture_flutter_firebase/src/routing/app_router.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/data/entries_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/invoices/invoice_generator.dart';

class JobEntriesScreen extends ConsumerWidget {
  const JobEntriesScreen({super.key, required this.jobId});
  final JobID jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobStreamProvider(jobId));
    return ScaffoldAsyncValueWidget<Job>(
      value: jobAsync,
      data: (job) => JobEntriesPageContents(job: job),
    );
  }
}

class JobEntriesPageContents extends ConsumerWidget {
  const JobEntriesPageContents({super.key, required this.job});
  final Job job;

  Future<void> _generateInvoice(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get user info
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      // Fetch all entries for this job
      final entriesRepo = ref.read(entriesRepositoryProvider);
      final entriesQuery = entriesRepo.queryEntries(
        uid: user.uid,
        jobId: job.id,
      );
      final entriesSnapshot = await entriesQuery.get();
      final entries = entriesSnapshot.docs.map((doc) => doc.data()).toList();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Check if there are entries
      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No time entries to generate invoice'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check if client info is available
      if (job.clientName.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add client information to this job first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Generate invoice number
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // UPDATED: Create line items based on JobPricingType
      final List<InvoiceLineItem> lineItems = [];
      
      if (job.pricingType == JobPricingType.hourly) {
        // Hourly: Generate line item for each entry
        lineItems.addAll(entries.map((entry) {
          final rate = (job.ratePerHour ?? 0).toDouble();
          return InvoiceLineItem(
            date: entry.start,
            description: entry.comment.isNotEmpty ? entry.comment : 'Work on ${job.name}',
            hours: entry.durationInHours,
            ratePerHour: rate,
          );
        }).toList());
      } else if (job.pricingType == JobPricingType.fixedPrice) {
        // Fixed Price: Single consolidated line item
        final totalHours = entries.fold(0.0, (sum, e) => sum + e.durationInHours);
        
        lineItems.add(InvoiceLineItem(
          date: DateTime.now(),
          description: 'Completed Project: ${job.name} (Time tracked: ${totalHours.toStringAsFixed(1)}h)',
          hours: 1.0, // Quantity of 1 unit
          ratePerHour: job.fixedPrice ?? 0.0, // This becomes the total amount
        ));
      } else if (job.pricingType == JobPricingType.unpaid) {
        // Unpaid: Documentation only, each entry listed with $0
        lineItems.addAll(entries.map((entry) {
          return InvoiceLineItem(
            date: entry.start,
            description: entry.comment.isNotEmpty ? entry.comment : 'Work on ${job.name}',
            hours: entry.durationInHours,
            ratePerHour: 0.0, // No rate for unpaid
          );
        }).toList());
      }

      // Prevent empty invoice
      if (lineItems.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No invoice items to generate'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Create invoice data
      final invoice = InvoiceData(
        // Invoice info
        invoiceNumber: invoiceNumber,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        
        // Your company info (freelancer)
        yourName: user.displayName ?? user.email?.split('@')[0] ?? 'Freelancer',
        yourEmail: user.email ?? '',
        yourPhone: '+60 12-345-6789', // TODO: Make this configurable
        yourAddress: null,
        yourWebsite: null,
        
        // Client info
        clientName: job.clientName,
        clientCompany: job.clientCompany ?? job.clientName,
        clientEmail: job.clientEmail ?? '',
        clientAddress: null,
        
        // Project details
        projectName: job.name,
        pricingType: job.pricingType, // ADDED: Required parameter
        lineItems: lineItems,
        
        // Payment details
        taxRate: 0.0,
        paymentTerms: 'Payment due within 14 days',
        bankName: null,
        accountNumber: null,
        notes: job.pricingType == JobPricingType.unpaid 
            ? 'This is a time tracking document for portfolio/documentation purposes. No payment required.'
            : 'Thank you for your business!',
      );

      // Generate and share PDF
      await InvoiceGenerator.generateAndShareInvoice(invoice);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              job.pricingType == JobPricingType.unpaid
                  ? 'Time tracking document generated successfully!'
                  : 'Invoice generated successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        // Try to pop the loading dialog, but catch if it's already closed
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
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
            title: Text(
              job.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: <Widget>[
              // Generate Invoice button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  tooltip: job.pricingType == JobPricingType.unpaid 
                      ? 'Generate Time Document'
                      : 'Generate Invoice',
                  onPressed: () => _generateInvoice(context, ref),
                ),
              ),
              // Edit button
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => context.goNamed(
                    AppRoute.editJob.name,
                    pathParameters: {'id': job.id},
                    extra: job,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: JobEntriesList(job: job),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => context.goNamed(
          AppRoute.addEntry.name,
          pathParameters: {'id': job.id},
          extra: job,
        ),
      ),
    );
  }
}