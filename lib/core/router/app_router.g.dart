// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's route tree.
///
/// The root [GoRouter.redirect] gates every route on the base level's
/// ([kBaseLevelId]) curriculum bundle load status: `/splash` while
/// loading, `/content-error` on an unsupported schema or parse failure,
/// otherwise the normal tree. A later level failing to load is handled
/// where that level is shown and never blocks the app. See
/// docs/ARCHITECTURE.md's content-loading strategy.
///
/// Once content is ready, the first-run agreement gates everything else:
/// until the current agreement version is accepted, every route leads to
/// `/welcome` (whose privacy policy and terms, `/legal/*`, stay readable).
/// Accepting opens `/home`, where the app guide starts. Sign-in is never a
/// gate — accounts are optional and live in Settings.
/// See docs/adr/0011-first-run-agreement-app-guide-and-account-deletion.md.
///
/// The lesson player, and any future placement/final-mission/
/// final-assessment flows, are deliberately full-screen pushes *outside*
/// the 5-tab `StatefulShellRoute` (hides the bottom nav during a lesson).

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The app's route tree.
///
/// The root [GoRouter.redirect] gates every route on the base level's
/// ([kBaseLevelId]) curriculum bundle load status: `/splash` while
/// loading, `/content-error` on an unsupported schema or parse failure,
/// otherwise the normal tree. A later level failing to load is handled
/// where that level is shown and never blocks the app. See
/// docs/ARCHITECTURE.md's content-loading strategy.
///
/// Once content is ready, the first-run agreement gates everything else:
/// until the current agreement version is accepted, every route leads to
/// `/welcome` (whose privacy policy and terms, `/legal/*`, stay readable).
/// Accepting opens `/home`, where the app guide starts. Sign-in is never a
/// gate — accounts are optional and live in Settings.
/// See docs/adr/0011-first-run-agreement-app-guide-and-account-deletion.md.
///
/// The lesson player, and any future placement/final-mission/
/// final-assessment flows, are deliberately full-screen pushes *outside*
/// the 5-tab `StatefulShellRoute` (hides the bottom nav during a lesson).

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's route tree.
  ///
  /// The root [GoRouter.redirect] gates every route on the base level's
  /// ([kBaseLevelId]) curriculum bundle load status: `/splash` while
  /// loading, `/content-error` on an unsupported schema or parse failure,
  /// otherwise the normal tree. A later level failing to load is handled
  /// where that level is shown and never blocks the app. See
  /// docs/ARCHITECTURE.md's content-loading strategy.
  ///
  /// Once content is ready, the first-run agreement gates everything else:
  /// until the current agreement version is accepted, every route leads to
  /// `/welcome` (whose privacy policy and terms, `/legal/*`, stay readable).
  /// Accepting opens `/home`, where the app guide starts. Sign-in is never a
  /// gate — accounts are optional and live in Settings.
  /// See docs/adr/0011-first-run-agreement-app-guide-and-account-deletion.md.
  ///
  /// The lesson player, and any future placement/final-mission/
  /// final-assessment flows, are deliberately full-screen pushes *outside*
  /// the 5-tab `StatefulShellRoute` (hides the bottom nav during a lesson).
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

String _$appRouterHash() => r'15f658589c3bea4b534f5f9efd121272cb1a6355';
