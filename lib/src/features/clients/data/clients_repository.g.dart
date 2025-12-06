// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientsRepositoryHash() => r'c3ca220b37a4dc1264ae0c740edc7dc5e9ec0a0f';

/// See also [clientsRepository].
@ProviderFor(clientsRepository)
final clientsRepositoryProvider = Provider<ClientsRepository>.internal(
  clientsRepository,
  name: r'clientsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clientsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClientsRepositoryRef = ProviderRef<ClientsRepository>;
String _$clientsQueryHash() => r'195a78e5045c30b3eaa1a45647d672c4f1267ffc';

/// See also [clientsQuery].
@ProviderFor(clientsQuery)
final clientsQueryProvider = AutoDisposeProvider<Query<Client>>.internal(
  clientsQuery,
  name: r'clientsQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$clientsQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClientsQueryRef = AutoDisposeProviderRef<Query<Client>>;
String _$clientStreamHash() => r'b90df1e225647f0cb85285b5e40a935866bb4321';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [clientStream].
@ProviderFor(clientStream)
const clientStreamProvider = ClientStreamFamily();

/// See also [clientStream].
class ClientStreamFamily extends Family<AsyncValue<Client>> {
  /// See also [clientStream].
  const ClientStreamFamily();

  /// See also [clientStream].
  ClientStreamProvider call(
    String clientId,
  ) {
    return ClientStreamProvider(
      clientId,
    );
  }

  @override
  ClientStreamProvider getProviderOverride(
    covariant ClientStreamProvider provider,
  ) {
    return call(
      provider.clientId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'clientStreamProvider';
}

/// See also [clientStream].
class ClientStreamProvider extends AutoDisposeStreamProvider<Client> {
  /// See also [clientStream].
  ClientStreamProvider(
    String clientId,
  ) : this._internal(
          (ref) => clientStream(
            ref as ClientStreamRef,
            clientId,
          ),
          from: clientStreamProvider,
          name: r'clientStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$clientStreamHash,
          dependencies: ClientStreamFamily._dependencies,
          allTransitiveDependencies:
              ClientStreamFamily._allTransitiveDependencies,
          clientId: clientId,
        );

  ClientStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.clientId,
  }) : super.internal();

  final String clientId;

  @override
  Override overrideWith(
    Stream<Client> Function(ClientStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClientStreamProvider._internal(
        (ref) => create(ref as ClientStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        clientId: clientId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Client> createElement() {
    return _ClientStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientStreamProvider && other.clientId == clientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, clientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClientStreamRef on AutoDisposeStreamProviderRef<Client> {
  /// The parameter `clientId` of this provider.
  String get clientId;
}

class _ClientStreamProviderElement
    extends AutoDisposeStreamProviderElement<Client> with ClientStreamRef {
  _ClientStreamProviderElement(super.provider);

  @override
  String get clientId => (origin as ClientStreamProvider).clientId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
