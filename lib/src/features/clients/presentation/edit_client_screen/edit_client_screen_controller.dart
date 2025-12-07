import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/data/clients_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';

part 'edit_client_screen_controller.g.dart';

@riverpod
class EditClientScreenController extends _$EditClientScreenController {
  @override
  FutureOr<void> build() {
    // no-op
  }

  Future<bool> submit({
    ClientID? clientId,
    required String name,
    required String company,
    String? email,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      throw AssertionError('User can\'t be null');
    }

    // Set loading state
    state = const AsyncLoading().copyWithPrevious(state);
    
    final repository = ref.read(clientsRepositoryProvider);

    // Check if company name is already in use (optional validation)
    final clients = await repository.fetchClients(uid: currentUser.uid);
    final allLowerCaseCompanies = clients
        .where((c) => c.id != clientId) // Exclude current client if editing
        .map((client) => client.company.toLowerCase())
        .toList();

    if (allLowerCaseCompanies.contains(company.toLowerCase())) {
      state = AsyncError(
        Exception('A client with this company name already exists'),
        StackTrace.current,
      );
      return false;
    }

    // Update existing client
    if (clientId != null) {
      final client = Client(
        id: clientId,
        name: name,
        company: company,
        email: email,
        phone: phone,
        address: address,
        notes: notes,
      );
      state = await AsyncValue.guard(
        () => repository.updateClient(uid: currentUser.uid, client: client),
      );
    } 
    // Create new client
    else {
      state = await AsyncValue.guard(
        () => repository.addClient(
          uid: currentUser.uid,
          name: name,
          company: company,
          email: email,
          phone: phone,
          address: address,
          notes: notes,
        ),
      );
    }

    return state.hasError == false;
  }
}