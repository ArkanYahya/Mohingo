import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/shared_preferences_provider.dart';
import '../domain/legal_documents.dart';

const _acceptedVersionKey = 'legal.acceptedAgreementVersion';
const _acceptedAtKey = 'legal.acceptedAgreementAt';

/// The agreement version this device's learner last accepted, or 0 if they
/// never have. Kept in SharedPreferences, not the progress database: it
/// belongs to the device, not to a learner or an account, and a progress
/// reset must never ask for it again.
class AcceptedAgreementVersion extends Notifier<int> {
  @override
  int build() =>
      ref.watch(sharedPreferencesProvider).getInt(_acceptedVersionKey) ?? 0;

  /// Records acceptance of the current [kAgreementVersion], and when.
  Future<void> acceptCurrent() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_acceptedVersionKey, kAgreementVersion);
    await prefs.setString(
      _acceptedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    state = kAgreementVersion;
  }
}

final acceptedAgreementVersionProvider =
    NotifierProvider<AcceptedAgreementVersion, int>(
      AcceptedAgreementVersion.new,
    );

/// Whether the learner has accepted the current agreement — the router's
/// gate in front of the whole app (`/welcome` until they have).
final agreementAcceptedProvider = Provider<bool>(
  (ref) => ref.watch(acceptedAgreementVersionProvider) >= kAgreementVersion,
);

/// The Markdown text of [document] in the interface language
/// ([languageCode]), read from the app's bundled assets.
final legalDocumentTextProvider = FutureProvider.autoDispose
    .family<String, (LegalDocument, String)>(
      (ref, key) => rootBundle.loadString(key.$1.assetPath(key.$2)),
    );
