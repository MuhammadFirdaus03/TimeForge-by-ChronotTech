import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/responsive_center.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/breakpoints.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/presentation/edit_job_screen/edit_job_screen_controller.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/async_value_ui.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  const EditJobScreen({super.key, this.jobId, this.job});
  final JobID? jobId;
  final Job? job;

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobPageState();
}

class _EditJobPageState extends ConsumerState<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  int? _ratePerHour;
  
  // NEW: Client information fields
  String? _clientName;
  String? _clientEmail;
  String? _clientCompany;
  String? _clientPhone;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _name = widget.job?.name;
      _ratePerHour = widget.job?.ratePerHour;
      // NEW: Initialize client fields
      _clientName = widget.job?.clientName;
      _clientEmail = widget.job?.clientEmail;
      _clientCompany = widget.job?.clientCompany;
      _clientPhone = widget.job?.clientPhone;
    }
  }

  bool _validateAndSaveForm() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _submit() async {
    if (_validateAndSaveForm()) {
      final success =
          await ref.read(editJobScreenControllerProvider.notifier).submit(
                jobId: widget.jobId,
                oldJob: widget.job,
                name: _name ?? '',
                ratePerHour: _ratePerHour ?? 0,
                // NEW: Pass client information
                clientName: _clientName ?? '',
                clientEmail: _clientEmail,
                clientCompany: _clientCompany,
                clientPhone: _clientPhone,
              );
      if (success && mounted) {
        context.pop();
      }
    }
  }

  // Toggle archive status
  Future<void> _toggleArchiveStatus() async {
    final job = widget.job;
    if (job == null) return;

    final newStatus = job.status == JobStatus.active 
        ? JobStatus.archived 
        : JobStatus.active;

    final success =
        await ref.read(editJobScreenControllerProvider.notifier).submit(
              jobId: widget.jobId,
              oldJob: job,
              name: job.name,
              ratePerHour: job.ratePerHour,
              status: newStatus,
              // NEW: Preserve client information when archiving
              clientName: job.clientName,
              clientEmail: job.clientEmail,
              clientCompany: job.clientCompany,
              clientPhone: job.clientPhone,
            );
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      editJobScreenControllerProvider,
      (_, state) => state.showAlertDialogOnError(context),
    );
    final state = ref.watch(editJobScreenControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job == null ? 'New Job' : 'Edit Job'),
        actions: <Widget>[
          TextButton(
            onPressed: state.isLoading ? null : _submit,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _buildContents(),
    );
  }

  Widget _buildContents() {
    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxContentWidth: Breakpoint.tablet,
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFormChildren(),
      ),
    );
  }

  List<Widget> _buildFormChildren() {
    final children = <Widget>[
      // Job Information Section
      Text(
        'Job Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Job name',
          hintText: 'e.g., Website Development',
          prefixIcon: Icon(Icons.work),
        ),
        keyboardAppearance: Brightness.light,
        initialValue: _name,
        validator: (value) =>
            (value ?? '').isNotEmpty ? null : 'Name can\'t be empty',
        onSaved: (value) => _name = value,
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Rate per hour',
          hintText: 'e.g., 50',
          prefixIcon: Icon(Icons.attach_money),
        ),
        keyboardAppearance: Brightness.light,
        initialValue: _ratePerHour != null ? '$_ratePerHour' : null,
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        ),
        onSaved: (value) => _ratePerHour = int.tryParse(value ?? '') ?? 0,
      ),
      
      // NEW: Client Information Section
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      Text(
        'Client Information (for invoicing)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Client name',
          hintText: 'e.g., John Smith',
          prefixIcon: Icon(Icons.person),
        ),
        keyboardAppearance: Brightness.light,
        initialValue: _clientName,
        validator: (value) =>
            (value ?? '').isNotEmpty ? null : 'Client name is required for invoicing',
        onSaved: (value) => _clientName = value,
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Client email',
          hintText: 'e.g., john@company.com',
          prefixIcon: Icon(Icons.email),
        ),
        keyboardAppearance: Brightness.light,
        keyboardType: TextInputType.emailAddress,
        initialValue: _clientEmail,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return null; // Optional field
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
        onSaved: (value) => _clientEmail = value?.isNotEmpty == true ? value : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Client company (optional)',
          hintText: 'e.g., Acme Corporation',
          prefixIcon: Icon(Icons.business),
        ),
        keyboardAppearance: Brightness.light,
        initialValue: _clientCompany,
        onSaved: (value) => _clientCompany = value?.isNotEmpty == true ? value : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        decoration: const InputDecoration(
          labelText: 'Client phone (optional)',
          hintText: 'e.g., +1 234 567 8900',
          prefixIcon: Icon(Icons.phone),
        ),
        keyboardAppearance: Brightness.light,
        keyboardType: TextInputType.phone,
        initialValue: _clientPhone,
        onSaved: (value) => _clientPhone = value?.isNotEmpty == true ? value : null,
      ),
    ];

    // Show archive button only when editing existing job
    if (widget.job != null) {
      final isArchived = widget.job!.status == JobStatus.archived;
      children.addAll([
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _toggleArchiveStatus,
          icon: Icon(isArchived ? Icons.unarchive : Icons.archive),
          label: Text(isArchived ? 'Unarchive Job' : 'Archive Job'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isArchived ? Colors.green : Colors.orange,
            side: BorderSide(
              color: isArchived ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isArchived
              ? 'This job is archived. Unarchive it to make it active again.'
              : 'Archive this job to hide it from your active jobs list.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ]);
    }

    return children;
  }
}