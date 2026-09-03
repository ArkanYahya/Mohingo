// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ensure_a1_enrollment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ensures the current learner has a `course_enrolments` row for A1 once
/// both the learner profile and the A1 content bundle are ready. Idempotent
/// — see [LearnerRepository.ensureEnrolled].

@ProviderFor(ensureA1Enrollment)
final ensureA1EnrollmentProvider = EnsureA1EnrollmentProvider._();

/// Ensures the current learner has a `course_enrolments` row for A1 once
/// both the learner profile and the A1 content bundle are ready. Idempotent
/// — see [LearnerRepository.ensureEnrolled].

final class EnsureA1EnrollmentProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Ensures the current learner has a `course_enrolments` row for A1 once
  /// both the learner profile and the A1 content bundle are ready. Idempotent
  /// — see [LearnerRepository.ensureEnrolled].
  EnsureA1EnrollmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureA1EnrollmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ensureA1EnrollmentHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return ensureA1Enrollment(ref);
  }
}

String _$ensureA1EnrollmentHash() =>
    r'5720de2d4b0051b2a0e7e5eb38ae7bfc51d126b4';
