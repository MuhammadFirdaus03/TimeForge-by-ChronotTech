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
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _fixedPriceController = TextEditingController();

  late JobPricingType _pricingType;
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _nameController.text = widget.job!.name;
      _pricingType = widget.job!.pricingType;
      _selectedClientId = widget.job!.clientId.isNotEmpty ? widget.job!.clientId : null;
      
      if (widget.job!.ratePerHour != null) {
        _rateController.text = widget.job!.ratePerHour.toString();
      }
      if (widget.job!.fixedPrice != null) {
        _fixedPriceController.text = widget.job!.fixedPrice!.toStringAsFixed(2);
      }
    } else {
      _pricingType = JobPricingType.hourly;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _fixedPriceController.dispose();
    super.dispose();
  }

  bool _validateAndSaveForm() {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      return false;
    }
    
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client to assign this job.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_pricingType == JobPricingType.hourly) {
      final rate = int.tryParse(_rateController.text);
      if (rate == null || rate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid hourly rate.'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }
    
    if (_pricingType == JobPricingType.fixedPrice) {
      final price = double.tryParse(_fixedPriceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid fixed price.'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }
    
    return true;
  }

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
    if (!_validateAndSaveForm()) return;
    
    final clientsAsyncValue = ref.read(clientsStreamProvider);
    
    clientsAsyncValue.when(
      data: (clients) async {
        final selectedClient = _getSelectedClient(clients);
        
        int? ratePerHour;
        double? fixedPrice;
        
        if (_pricingType == JobPricingType.hourly) {
          ratePerHour = int.tryParse(_rateController.text);
        } else if (_pricingType == JobPricingType.fixedPrice) {
          fixedPrice = double.tryParse(_fixedPriceController.text);
        }
        
        final success = await ref.read(editJobScreenControllerProvider.notifier).submit(
          jobId: widget.jobId,
          oldJob: widget.job,
          name: _nameController.text,
          clientId: _selectedClientId ?? '',
          pricingType: _pricingType,
          ratePerHour: ratePerHour,
          fixedPrice: fixedPrice,
          status: widget.job?.status,
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
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.job == null ? 'New Job' : 'Edit Job',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white, size: 20),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildContents(),
    );
  }

  Widget _buildContents() {
    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxContentWidth: Breakpoint.tablet,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Card with Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[400]!,
                    Colors.purple[600]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job == null ? 'Create New Job' : 'Update Job',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.job == null 
                              ? 'Add a new project to your portfolio'
                              : 'Update job information and settings',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Job Information
          _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'Job Details',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          
          _buildStyledTextField(
            label: 'Job Name',
            hint: 'e.g., Website Development',
            icon: Icons.work,
            controller: _nameController,
            validator: (value) =>
                (value ?? '').isNotEmpty ? null : 'Job name is required',
          ),
          
          const SizedBox(height: 24),
          
          // Section 2: Client Selection
          _buildSectionHeader(
            icon: Icons.people_outline,
            title: 'Select Client',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          
          Consumer(
            builder: (context, ref, child) {
              final clientsAsync = ref.watch(clientsStreamProvider);
              return AsyncValueWidget<List<Client>>(
                value: clientsAsync,
                data: (clients) {
                  if (clients.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No clients found. Please create a client first from the Clients tab.',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people,
                            size: 20,
                            color: Colors.green,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      initialValue: _selectedClientId,
                      hint: const Text('Choose a client'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('--- Select a Client ---'),
                        ),
                        ...clients.map((client) {
                          final displayLabel = client.company.isNotEmpty 
                              ? '${client.company} (${client.name})' 
                              : client.name;
                          return DropdownMenuItem<String>(
                            value: client.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      client.company.isNotEmpty
                                          ? client.company.substring(0, 1).toUpperCase()
                                          : client.name.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedClientId = newValue;
                        });
                      },
                      validator: (value) => 
                        (value == null || value.isEmpty) ? 'Client assignment is required' : null,
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),
          
          // Section 3: Pricing
          _buildSectionHeader(
            icon: Icons.attach_money,
            title: 'Pricing Type',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          
          // Pricing Type Selector
          SegmentedButton<JobPricingType>(
            segments: const [
              ButtonSegment<JobPricingType>(
                value: JobPricingType.hourly,
                label: Text('Hourly'),
                icon: Icon(Icons.schedule, size: 18),
              ),
              ButtonSegment<JobPricingType>(
                value: JobPricingType.fixedPrice,
                label: Text('Fixed'),
                icon: Icon(Icons.payments, size: 18),
              ),
              ButtonSegment<JobPricingType>(
                value: JobPricingType.unpaid,
                label: Text('Unpaid'),
                icon: Icon(Icons.volunteer_activism, size: 18),
              ),
            ],
            selected: <JobPricingType>{_pricingType},
            onSelectionChanged: (Set<JobPricingType> newSelection) {
              setState(() {
                _pricingType = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Conditional Pricing Input Field
          if (_pricingType == JobPricingType.hourly)
            _buildStyledTextField(
              label: 'Rate per Hour',
              hint: 'e.g., 50',
              icon: Icons.schedule,
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hourly rate is required';
                }
                if ((int.tryParse(value) ?? 0) <= 0) {
                  return 'Rate must be positive';
                }
                return null;
              },
            )
          else if (_pricingType == JobPricingType.fixedPrice)
            _buildStyledTextField(
              label: 'Fixed Project Price',
              hint: 'e.g., 2500.00',
              icon: Icons.sell,
              controller: _fixedPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fixed price is required';
                }
                if ((double.tryParse(value) ?? 0.0) <= 0.0) {
                  return 'Price must be positive';
                }
                return null;
              },
            ),
          
          // Archive section
          if (widget.job != null) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            _buildSectionHeader(
              icon: Icons.archive_outlined,
              title: 'Job Status',
              color: widget.job!.status == JobStatus.archived ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            
            _buildArchiveButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildArchiveButton() {
    final isArchived = widget.job!.status == JobStatus.archived;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isArchived 
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isArchived ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggleArchiveStatus,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isArchived ? Icons.unarchive : Icons.archive,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArchived ? 'Unarchive Job' : 'Archive Job',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArchived
                            ? 'Make this job active again'
                            : 'Hide this job from your active jobs list',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}