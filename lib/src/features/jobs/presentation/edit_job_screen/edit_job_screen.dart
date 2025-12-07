import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/async_value_widget.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/responsive_center.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/breakpoints.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/data/clients_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';
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
  late JobPricingType _pricingType;
  int? _ratePerHour;
  double? _fixedPrice;
  String? _selectedClientId; // Changed from ClientID? to String?

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _name = widget.job?.name;
      _pricingType = widget.job?.pricingType ?? JobPricingType.hourly;
      _ratePerHour = widget.job?.ratePerHour;
      _fixedPrice = widget.job?.fixedPrice;
      _selectedClientId = widget.job?.clientId.isNotEmpty == true ? widget.job!.clientId : null;
    } else {
      _pricingType = JobPricingType.hourly;
    }
  }

  bool _validateAndSaveForm() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      
      if (_selectedClientId == null || _selectedClientId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client to assign this job.'))
        );
        return false;
      }

      if (_pricingType == JobPricingType.hourly && (_ratePerHour == null || _ratePerHour! <= 0)) {
        return false;
      }
      if (_pricingType == JobPricingType.fixedPrice && (_fixedPrice == null || _fixedPrice! <= 0)) {
        return false;
      }
      
      return true;
    }
    return false;
  }

  // Helper method to get selected client details
  Client? _getSelectedClient(List<Client> clients) {
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      return null;
    }
    try {
      return clients.firstWhere((c) => c.id == _selectedClientId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_validateAndSaveForm()) {
      // Get the current list of clients
      final clientsAsyncValue = ref.read(clientsStreamProvider);
      
      clientsAsyncValue.when(
        data: (clients) async {
          final selectedClient = _getSelectedClient(clients);
          
          final success = await ref.read(editJobScreenControllerProvider.notifier).submit(
            jobId: widget.jobId,
            oldJob: widget.job,
            name: _name ?? '',
            clientId: _selectedClientId ?? '',
            pricingType: _pricingType,
            ratePerHour: _pricingType == JobPricingType.hourly ? _ratePerHour : null,
            fixedPrice: _pricingType == JobPricingType.fixedPrice ? _fixedPrice : null,
            status: widget.job?.status,
            // Pass the actual client details
            clientName: selectedClient?.name ?? '',
            clientEmail: selectedClient?.email,
            clientCompany: selectedClient?.company,
            clientPhone: selectedClient?.phone,
          );
          
          if (success && mounted) {
            context.pop();
          }
        },
        loading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading client information...')),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading clients: $error')),
          );
        },
      );
    }
  }

  Future<void> _toggleArchiveStatus() async {
    final job = widget.job;
    if (job == null) return;

    final newStatus = job.status == JobStatus.active 
        ? JobStatus.archived 
        : JobStatus.active;

    final success = await ref.read(editJobScreenControllerProvider.notifier).submit(
      jobId: widget.jobId,
      oldJob: job,
      name: job.name,
      clientId: job.clientId,
      pricingType: job.pricingType,
      ratePerHour: job.ratePerHour,
      fixedPrice: job.fixedPrice,
      status: newStatus,
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
    final List<Widget> children = [
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
      
      // Client Selection Dropdown
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      Text(
        'Select Client',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      const SizedBox(height: 12),
      Consumer(
        builder: (context, ref, child) {
          final clientsAsync = ref.watch(clientsStreamProvider);
          return AsyncValueWidget<List<Client>>(
            value: clientsAsync,
            data: (clients) {
              if (clients.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No clients found. Please create a client first from the Clients tab.',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final dropdownItems = clients.map((client) {
                final displayLabel = client.company.isNotEmpty 
                    ? '${client.company} (${client.name})' 
                    : client.name;
                return DropdownMenuItem<String>(
                  value: client.id,
                  child: Text(displayLabel),
                );
              }).toList();

              dropdownItems.insert(0, DropdownMenuItem<String>(
                value: '',
                child: Text(
                  '--- Select a Client ---', 
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ));

              String initialValue = _selectedClientId ?? '';
              if (initialValue.isNotEmpty && !clients.any((c) => c.id == initialValue)) {
                initialValue = '';
                _selectedClientId = null;
              }
              
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Assigned Client',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                initialValue: initialValue.isEmpty ? null : initialValue,
                items: dropdownItems,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClientId = (newValue == null || newValue.isEmpty) ? null : newValue;
                  });
                },
                validator: (value) => 
                  (value == null || value.isEmpty) ? 'Client assignment is required' : null,
              );
            },
          );
        },
      ),

      // Pricing Type Selector
      const SizedBox(height: 24),
      Text(
        'Pricing Type',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 8),
      SegmentedButton<JobPricingType>(
        segments: const <ButtonSegment<JobPricingType>>[
          ButtonSegment<JobPricingType>(
            value: JobPricingType.hourly,
            label: Text('Hourly'),
          ),
          ButtonSegment<JobPricingType>(
            value: JobPricingType.fixedPrice,
            label: Text('Fixed Price'),
          ),
          ButtonSegment<JobPricingType>(
            value: JobPricingType.unpaid,
            label: Text('Unpaid'),
          ),
        ],
        selected: <JobPricingType>{_pricingType},
        onSelectionChanged: (Set<JobPricingType> newSelection) {
          setState(() {
            _pricingType = newSelection.first;
            if (_pricingType != JobPricingType.hourly) {
               _ratePerHour = null;
            } else {
              _ratePerHour ??= 0;
            }
            if (_pricingType != JobPricingType.fixedPrice) {
               _fixedPrice = null;
            }
          });
        },
      ),
      const SizedBox(height: 16),
      
      // Conditional Pricing Input Field
      if (_pricingType == JobPricingType.hourly)
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
          validator: (value) {
            if (_pricingType == JobPricingType.hourly && (value == null || value.isEmpty)) {
              return 'Hourly rate is required';
            }
            if (_pricingType == JobPricingType.hourly && (int.tryParse(value ?? '') ?? 0) <= 0) {
              return 'Rate must be positive';
            }
            return null;
          },
          onSaved: (value) => _ratePerHour = int.tryParse(value ?? '') ?? 0,
        )
      else if (_pricingType == JobPricingType.fixedPrice)
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Fixed Project Price',
            hintText: 'e.g., 2500.00',
            prefixIcon: Icon(Icons.sell),
          ),
          keyboardAppearance: Brightness.light,
          initialValue: _fixedPrice?.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: true,
          ),
          validator: (value) {
            if (_pricingType == JobPricingType.fixedPrice && (value == null || value.isEmpty)) {
              return 'Fixed price is required';
            }
            if (_pricingType == JobPricingType.fixedPrice && (double.tryParse(value ?? '') ?? 0.0) <= 0.0) {
              return 'Price must be positive';
            }
            return null;
          },
          onSaved: (value) => _fixedPrice = double.tryParse(value ?? '') ?? 0.0,
        ),
    ];

    // Archive button section
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