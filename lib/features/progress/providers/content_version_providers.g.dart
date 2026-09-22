// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_version_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
/// whose content moved under this learner. Returns the unit ids it flagged.
///
/// The read of [ContentVersionRepository.latest] happens **before**
/// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
/// snapshot would be the row just written, every diff would come back
/// empty, and this would quietly do nothing for the rest of the app's life
/// — while every test that only covers a fresh install still passed.
///
/// Fired from `lib/app.dart` for the level the learner is working in. It
/// re-fires when they switch level, because that invalidates
/// `currentLevelIdProvider`. A level they hold progress in but are not
/// currently working in is checked the next time they return to it, which
/// is also the next time they could see a unit row say so — levels load
/// lazily and checking all of them at launch would undo that.

@ProviderFor(recordContentVersionAndFlagDrift)
final recordContentVersionAndFlagDriftProvider =
    RecordContentVersionAndFlagDriftFamily._();

/// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
/// whose content moved under this learner. Returns the unit ids it flagged.
///
/// The read of [ContentVersionRepository.latest] happens **before**
/// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
/// snapshot would be the row just written, every diff would come back
/// empty, and this would quietly do nothing for the rest of the app's life
/// — while every test that only covers a fresh install still passed.
///
/// Fired from `lib/app.dart` for the level the learner is working in. It
/// re-fires when they switch level, because that invalidates
/// `currentLevelIdProvider`. A level they hold progress in but are not
/// currently working in is checked the next time they return to it, which
/// is also the next time they could see a unit row say so — levels load
/// lazily and checking all of them at launch would undo that.

final class RecordContentVersionAndFlagDriftProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
  /// whose content moved under this learner. Returns the unit ids it flagged.
  ///
  /// The read of [ContentVersionRepository.latest] happens **before**
  /// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
  /// snapshot would be the row just written, every diff would come back
  /// empty, and this would quietly do nothing for the rest of the app's life
  /// — while every test that only covers a fresh install still passed.
  ///
  /// Fired from `lib/app.dart` for the level the learner is working in. It
  /// re-fires when they switch level, because that invalidates
  /// `currentLevelIdProvider`. A level they hold progress in but are not
  /// currently working in is checked the next time they return to it, which
  /// is also the next time they could see a unit row say so — levels load
  /// lazily and checking all of them at launch would undo that.
  RecordContentVersionAndFlagDriftProvider._({
    required RecordContentVersionAndFlagDriftFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordContentVersionAndFlagDriftProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordContentVersionAndFlagDriftHash();

  @override
  String toString() {
    return r'recordContentVersionAndFlagDriftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return recordContentVersionAndFlagDrift(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordContentVersionAndFlagDriftProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordContentVersionAndFlagDriftHash() =>
    r'541fc020865e5bcec6abafb148eed297ba8ae38e';

/// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
/// whose content moved under this learner. Returns the unit ids it flagged.
///
/// The read of [ContentVersionRepository.latest] happens **before**
/// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
/// snapshot would be the row just written, every diff would come back
/// empty, and this would quietly do nothing for the rest of the app's life
/// — while every test that only covers a fresh install still passed.
///
/// Fired from `lib/app.dart` for the level the learner is working in. It
/// re-fires when they switch level, because that invalidates
/// `currentLevelIdProvider`. A level they hold progress in but are not
/// currently working in is checked the next time they return to it, which
/// is also the next time they could see a unit row say so — levels load
/// lazily and checking all of them at launch would undo that.

final class RecordContentVersionAndFlagDriftFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Set<String>>, String> {
  RecordContentVersionAndFlagDriftFamily._()
    : super(
        retry: null,
        name: r'recordContentVersionAndFlagDriftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
  /// whose content moved under this learner. Returns the unit ids it flagged.
  ///
  /// The read of [ContentVersionRepository.latest] happens **before**
  /// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
  /// snapshot would be the row just written, every diff would come back
  /// empty, and this would quietly do nothing for the rest of the app's life
  /// — while every test that only covers a fresh install still passed.
  ///
  /// Fired from `lib/app.dart` for the level the learner is working in. It
  /// re-fires when they switch level, because that invalidates
  /// `currentLevelIdProvider`. A level they hold progress in but are not
  /// currently working in is checked the next time they return to it, which
  /// is also the next time they could see a unit row say so — levels load
  /// lazily and checking all of them at launch would undo that.

  RecordContentVersionAndFlagDriftProvider call(String levelId) =>
      RecordContentVersionAndFlagDriftProvider._(argument: levelId, from: this);

  @override
  String toString() => r'recordContentVersionAndFlagDriftProvider';
}
