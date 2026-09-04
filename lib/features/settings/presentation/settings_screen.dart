import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/locale_preference_provider.dart';
import '../../../core/theme/color_seed.dart';
import '../../../core/theme/theme_preferences_provider.dart';
import '../../../data/local/database_provider.dart';
import '../../grammar/providers/grammar_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/ensure_a1_enrollment_provider.dart';
import '../../review/providers/review_providers.dart';
import '../../speech/domain/speech_recognition_service.dart';
import '../../speech/providers/speech_providers.dart';
import '../../speech/providers/tts_preferences_provider.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';

/// Settings tab landing screen.
///
/// Interface language, theme mode, and colour theme all read/write
/// preferences that were already wired at the app root in earlier phases
/// (`localePreferenceProvider`/`themeModePreferenceProvider`/
/// `colorSeedPreferenceProvider`) — this screen is the first UI that
/// actually exposes them to a learner, per docs/DESIGN_SYSTEM.md's
/// "changes apply immediately, no restart" rule. Speech, About, Reset
/// progress, and Backup & sync round out the full Settings surface for v1.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.settingsInterfaceLanguageTitle),
          const _InterfaceLanguagePicker(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsThemeModeTitle),
          const _ThemeModePicker(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsColorThemeTitle),
          const _ColorThemePicker(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsSpeechTitle),
          const _SpeechStatusCard(),
          const SizedBox(height: 16),
          const _TtsRateSlider(),
          const _TtsPitchSlider(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsAboutTitle),
          _InfoCard(l10n.settingsAboutBody),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsResetProgressTitle),
          const _ResetProgressButton(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsBackupTitle),
          _InfoCard(l10n.settingsBackupBody),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
    );
  }
}

class _InterfaceLanguagePicker extends ConsumerWidget {
  const _InterfaceLanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    return SegmentedButton<Locale>(
      segments: const [
        // Each language's own name is shown in its own script regardless of
        // the current interface language — a language picker's own labels
        // are identity strings, not translated content.
        ButtonSegment(value: Locale('ar'), label: Text('العربية')),
        ButtonSegment(value: Locale('en'), label: Text('English')),
      ],
      selected: {locale},
      onSelectionChanged: (selection) =>
          ref.read(localePreferenceProvider.notifier).set(selection.first),
    );
  }
}

class _ThemeModePicker extends ConsumerWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModePreferenceProvider);
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(l10n.settingsThemeModeLight),
          icon: const Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(l10n.settingsThemeModeDark),
          icon: const Icon(Icons.dark_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(l10n.settingsThemeModeSystem),
          icon: const Icon(Icons.brightness_auto_outlined),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) =>
          ref.read(themeModePreferenceProvider.notifier).set(selection.first),
    );
  }
}

class _ColorThemePicker extends ConsumerWidget {
  const _ColorThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(colorSeedPreferenceProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      children: [
        for (final seed in AppColorSeed.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Semantics(
              label: isArabic ? seed.labelAr : seed.labelEn,
              button: true,
              selected: seed == selected,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    ref.read(colorSeedPreferenceProvider.notifier).set(seed),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: seed.seedColor,
                  child: seed == selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResetProgressButton extends ConsumerWidget {
  const _ResetProgressButton();

  Future<void> _confirmAndReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetProgressConfirmTitle),
        content: Text(l10n.settingsResetProgressConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsResetProgressCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsResetProgressConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    final learner = await ref.read(currentLearnerProvider.future);
    await db.resetProgressForLearner(learner.id);

    ref.invalidate(allUnitProgressProvider);
    ref.invalidate(allVocabularyReviewStateProvider);
    ref.invalidate(allGrammarReviewStateProvider);
    ref.invalidate(weakObjectivesProvider);
    ref.invalidate(dueVocabularyProvider);
    ref.invalidate(ensureA1EnrollmentProvider);
    ref.invalidate(currentStreakDaysProvider);
    ref.invalidate(latestPlacementAttemptProvider);
    ref.invalidate(latestFinalMissionAttemptProvider);
    ref.invalidate(latestFinalAssessmentAttemptProvider);
    // A family: invalidating the family itself clears every already-built
    // (learnerId, unitId) instance, which is what a full wipe needs.
    ref.invalidate(lessonProgressForUnitProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsResetProgressDone)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: () => _confirmAndReset(context, ref),
      child: Text(l10n.settingsResetProgressButton),
    );
  }
}

class _SpeechStatusCard extends ConsumerWidget {
  const _SpeechStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final capabilitiesAsync = ref.watch(currentSpeechCapabilitiesProvider);

    return capabilitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Text('$error'),
      data: (capabilities) {
        final micLine = switch (capabilities.micPermission) {
          SpeechPermissionStatus.granted => l10n.settingsMicPermissionGranted,
          SpeechPermissionStatus.denied => l10n.settingsMicPermissionDenied,
          SpeechPermissionStatus.permanentlyDenied =>
            l10n.settingsMicPermissionPermanentlyDenied,
          SpeechPermissionStatus.notDetermined =>
            l10n.settingsMicPermissionNotDetermined,
        };
        final sttLine = capabilities.sttAvailableForLocale
            ? l10n.settingsSttAvailable
            : l10n.settingsSttUnavailable;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  icon:
                      capabilities.micPermission ==
                          SpeechPermissionStatus.granted
                      ? Icons.mic
                      : Icons.mic_off,
                  text: micLine,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  icon: capabilities.sttAvailableForLocale
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  text: sttLine,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _TtsRateSlider extends ConsumerWidget {
  const _TtsRateSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rate = ref.watch(ttsRatePreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsSpeechRate),
        Slider(
          value: rate,
          min: 0.25,
          max: 1.0,
          onChanged: (v) => ref.read(ttsRatePreferenceProvider.notifier).set(v),
        ),
      ],
    );
  }
}

class _TtsPitchSlider extends ConsumerWidget {
  const _TtsPitchSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pitch = ref.watch(ttsPitchPreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsSpeechPitch),
        Slider(
          value: pitch,
          min: 0.5,
          max: 2.0,
          onChanged: (v) =>
              ref.read(ttsPitchPreferenceProvider.notifier).set(v),
        ),
      ],
    );
  }
}
