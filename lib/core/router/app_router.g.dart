// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's route tree.
///
/// Phase 3 scope: the 5-tab shell only, with placeholder screens. The
/// content-load root [GoRouter.redirect] gate (routing to a splash/
/// unsupported-content screen based on the curriculum bundle's load status)
/// is added once `lib/content/` exists — see docs/ARCHITECTURE.md's
/// navigation map. Likewise, the full-screen pushes for the lesson player,
/// placement test, final mission, and final assessment are added once their
/// owning features exist.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The app's route tree.
///
/// Phase 3 scope: the 5-tab shell only, with placeholder screens. The
/// content-load root [GoRouter.redirect] gate (routing to a splash/
/// unsupported-content screen based on the curriculum bundle's load status)
/// is added once `lib/content/` exists — see docs/ARCHITECTURE.md's
/// navigation map. Likewise, the full-screen pushes for the lesson player,
/// placement test, final mission, and final assessment are added once their
/// owning features exist.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's route tree.
  ///
  /// Phase 3 scope: the 5-tab shell only, with placeholder screens. The
  /// content-load root [GoRouter.redirect] gate (routing to a splash/
  /// unsupported-content screen based on the curriculum bundle's load status)
  /// is added once `lib/content/` exists — see docs/ARCHITECTURE.md's
  /// navigation map. Likewise, the full-screen pushes for the lesson player,
  /// placement test, final mission, and final assessment are added once their
  /// owning features exist.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'43f34445320348ab2368bd86c6e4995a60d3e3aa';
