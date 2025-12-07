import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter_architecture_flutter_firebase/src/common_widgets/responsive_center.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/breakpoints.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/presentation/edit_client_screen/edit_client_screen_controller.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/async_value_ui.dart';

class EditClientScreen extends ConsumerStatefulWidget {
  const EditClientScreen({super.key, this.clientId, this.client});
  final ClientID? clientId;
  final Client? client;

  @override
  ConsumerState<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends ConsumerState<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _company;
  String? _email;
  String? _phone;
  String? _address;
  String? _notes;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _name = widget.client!.name;
      _company = widget.client!.company;
      _email = widget.client!.email;
      _phone = widget.client!.phone;
      _address = widget.client!.address;
      _notes = widget.client!.notes;
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
      final success = await ref.read(editClientScreenControllerProvider.notifier).submit(
        clientId: widget.clientId,
        name: _name ?? '',
        company: _company ?? '',
        email: _email,
        phone: _phone,
        address: _address,
        notes: _notes,
      );
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      editClientScreenControllerProvider,
      (_, state) => state.showAlertDialogOnError(context),
    );
    final state = ref.watch(editClientScreenControllerProvider);
    
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
              widget.client == null ? 'New Client' : 'Edit Client',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                      Icons.business_center,
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
                          widget.client == null ? 'New Client' : 'Update Client',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.client == null 
                              ? 'Add a new client to your portfolio'
                              : 'Update client information',
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
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Client Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Company Name
          _buildStyledTextField(
            label: 'Company Name *',
            hint: 'e.g., Acme Corporation',
            icon: Icons.business,
            initialValue: _company,
            validator: (value) =>
                (value ?? '').isNotEmpty ? null : 'Company name is required',
            onSaved: (value) => _company = value,
          ),
          const SizedBox(height: 20),
          
          // Contact Person
          _buildStyledTextField(
            label: 'Contact Person *',
            hint: 'e.g., John Smith',
            icon: Icons.person,
            initialValue: _name,
            validator: (value) =>
                (value ?? '').isNotEmpty ? null : 'Contact name is required',
            onSaved: (value) => _name = value,
          ),
          const SizedBox(height: 20),
          
          // Email
          _buildStyledTextField(
            label: 'Email',
            hint: 'e.g., john@acme.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            initialValue: _email,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
              }
              return null;
            },
            onSaved: (value) => _email = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 20),
          
          // Phone
          _buildStyledTextField(
            label: 'Phone',
            hint: 'e.g., +60 12-345-6789',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            initialValue: _phone,
            onSaved: (value) => _phone = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 20),
          
          // Address
          _buildStyledTextField(
            label: 'Address',
            hint: 'e.g., 123 Main St, City',
            icon: Icons.location_on,
            maxLines: 2,
            initialValue: _address,
            onSaved: (value) => _address = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 20),
          
          // Notes
          _buildStyledTextField(
            label: 'Notes',
            hint: 'Any additional information...',
            icon: Icons.note,
            maxLines: 3,
            maxLength: 200,
            initialValue: _notes,
            onSaved: (value) => _notes = value?.isNotEmpty == true ? value : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
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
          counterStyle: TextStyle(color: Colors.grey[600]),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        initialValue: initialValue,
        validator: validator,
        onSaved: onSaved,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}