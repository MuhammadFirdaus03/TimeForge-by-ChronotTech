import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // NEW IMPORT
import 'package:starter_architecture_flutter_firebase/src/features/clients/data/clients_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/clients/domain/client.dart';
import 'package:starter_architecture_flutter_firebase/src/routing/app_router.dart'; // NEW IMPORT
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsQuery = ref.watch(clientsQueryProvider);
    
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
              'Clients',
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
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () {
                    // UPDATED: Navigate to add client screen
                    context.goNamed(AppRoute.addClient.name);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: FirestoreListView<Client>(
        query: clientsQuery,
        emptyBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No clients yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first client',
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
          final client = doc.data();
          return Dismissible(
            key: Key('client-${client.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              // Show confirmation dialog before deleting
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Client'),
                  content: Text(
                    'Are you sure you want to delete ${client.displayName}? '
                    'This will not delete associated jobs.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              // Delete the client
              try {
                final user = ref.read(firebaseAuthProvider).currentUser;
                if (user != null) {
                  await ref.read(clientsRepositoryProvider).deleteClient(
                    uid: user.uid,
                    clientId: client.id,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${client.displayName} deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting client: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            child: ClientCard(
              client: client,
              onTap: () {
                // UPDATED: Navigate to client details (view jobs)
                context.goNamed(
                  AppRoute.clientDetails.name,
                  pathParameters: {'id': client.id},
                  extra: client,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
  });
  
  final Client client;
  final VoidCallback? onTap;

  List<Color> _getGradient() {
    final hash = client.company.hashCode;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Teal
    ];
    return gradients[hash.abs() % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
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
                // Avatar circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.company.isNotEmpty 
                          ? client.company.substring(0, 1).toUpperCase()
                          : client.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Client details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.company.isNotEmpty ? client.company : client.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (client.company.isNotEmpty && client.name.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.name,
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
                      if (client.email != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.email!,
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
                      ],
                    ],
                  ),
                ),
                // Arrow icon
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