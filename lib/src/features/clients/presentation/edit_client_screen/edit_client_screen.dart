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
      appBar: AppBar(
        title: Text(widget.client == null ? 'New Client' : 'Edit Client'),
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
        children: [
          Text(
            'Client Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Company Name (Primary)
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Company Name *',
              hintText: 'e.g., Acme Corporation',
              prefixIcon: Icon(Icons.business),
            ),
            initialValue: _company,
            validator: (value) =>
                (value ?? '').isNotEmpty ? null : 'Company name is required',
            onSaved: (value) => _company = value,
          ),
          const SizedBox(height: 16),
          
          // Contact Person Name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Contact Person *',
              hintText: 'e.g., John Smith',
              prefixIcon: Icon(Icons.person),
            ),
            initialValue: _name,
            validator: (value) =>
                (value ?? '').isNotEmpty ? null : 'Contact name is required',
            onSaved: (value) => _name = value,
          ),
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'e.g., john@acme.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            initialValue: _email,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // Basic email validation
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
              }
              return null;
            },
            onSaved: (value) => _email = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 16),
          
          // Phone
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'e.g., +60 12-345-6789',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            initialValue: _phone,
            onSaved: (value) => _phone = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 16),
          
          // Address
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'e.g., 123 Main St, City',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
            initialValue: _address,
            onSaved: (value) => _address = value?.isNotEmpty == true ? value : null,
          ),
          const SizedBox(height: 16),
          
          // Notes
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Any additional information...',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            maxLength: 200,
            initialValue: _notes,
            onSaved: (value) => _notes = value?.isNotEmpty == true ? value : null,
          ),
        ],
      ),
    );
  }
}