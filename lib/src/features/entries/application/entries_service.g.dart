// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$entriesServiceHash() => r'106c29e519ac1706956f952263745337399caba9';

/// See also [entriesService].
@ProviderFor(entriesService)
final entriesServiceProvider = AutoDisposeProvider<EntriesService>.internal(
  entriesService,
  name: r'entriesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$entriesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EntriesServiceRef = AutoDisposeProviderRef<EntriesService>;
String _$entriesTileModelStreamHash() =>
    r'a87a7a9826137f864785233c0e20ad56d5b267f4';

/// See also [entriesTileModelStream].
@ProviderFor(entriesTileModelStream)
final entriesTileModelStreamProvider =
    AutoDisposeStreamProvider<List<EntriesListTileModel>>.internal(
  entriesTileModelStream,
  name: r'entriesTileModelStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$entriesTileModelStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EntriesTileModelStreamRef
    = AutoDisposeStreamProviderRef<List<EntriesListTileModel>>;
String _$entriesFilterHash() => r'373e4ea7617b5d3cd9170d4da7cc7c0c36deabca';

/// See also [EntriesFilter].
@ProviderFor(EntriesFilter)
final entriesFilterProvider =
    AutoDisposeNotifierProvider<EntriesFilter, EntriesFilterState>.internal(
  EntriesFilter.new,
  name: r'entriesFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$entriesFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EntriesFilter = AutoDisposeNotifier<EntriesFilterState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
