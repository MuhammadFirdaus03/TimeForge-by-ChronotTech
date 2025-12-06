import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/domain/app_user.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';

part 'clients_repository.g.dart';

class ClientsRepository {
  const ClientsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String clientPath(String uid, String clientId) => 
      'users/$uid/clients/$clientId';
  static String clientsPath(String uid) => 'users/$uid/clients';

  // Create
  Future<String> addClient({
    required UserID uid,
    required String name,
    required String company,
    String? email,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final docRef = await _firestore.collection(clientsPath(uid)).add({
      'name': name,
      'company': company,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return docRef.id;
  }

  // Update
  Future<void> updateClient({
    required UserID uid,
    required Client client,
  }) =>
      _firestore.doc(clientPath(uid, client.id)).update(client.toMap());

  // Delete
  Future<void> deleteClient({
    required UserID uid,
    required ClientID clientId,
  }) async {
    // Note: We should probably check if there are jobs linked to this client
    // and either prevent deletion or handle orphaned jobs
    final clientRef = _firestore.doc(clientPath(uid, clientId));
    await clientRef.delete();
  }

  // Read single client
  Stream<Client> watchClient({
    required UserID uid,
    required ClientID clientId,
  }) =>
      _firestore
          .doc(clientPath(uid, clientId))
          .withConverter<Client>(
            fromFirestore: (snapshot, _) =>
                Client.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (client, _) => client.toMap(),
          )
          .snapshots()
          .map((snapshot) => snapshot.data()!);

  // Read all clients
  Stream<List<Client>> watchClients({required UserID uid}) =>
      queryClients(uid: uid)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  // Query clients
  Query<Client> queryClients({required UserID uid}) =>
      _firestore.collection(clientsPath(uid)).withConverter(
            fromFirestore: (snapshot, _) =>
                Client.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (client, _) => client.toMap(),
          );

  // Fetch clients (one-time read)
  Future<List<Client>> fetchClients({required UserID uid}) async {
    final clients = await queryClients(uid: uid).get();
    return clients.docs.map((doc) => doc.data()).toList();
  }
}

@Riverpod(keepAlive: true)
ClientsRepository clientsRepository(ClientsRepositoryRef ref) {
  return ClientsRepository(FirebaseFirestore.instance);
}

@riverpod
Query<Client> clientsQuery(ClientsQueryRef ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw AssertionError('User can\'t be null');
  }
  final repository = ref.watch(clientsRepositoryProvider);
  return repository.queryClients(uid: user.uid);
}

@riverpod
Stream<Client> clientStream(ClientStreamRef ref, ClientID clientId) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw AssertionError('User can\'t be null');
  }
  final repository = ref.watch(clientsRepositoryProvider);
  return repository.watchClient(uid: user.uid, clientId: clientId);
}