import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/app_version.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/locale_preference_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/color_seed.dart';
import '../../../core/theme/theme_preferences_provider.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/local/database_provider.dart';
import '../../grammar/providers/grammar_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../review/providers/review_providers.dart';
import '../../speech/domain/speech_recognition_service.dart';
import '../../speech/providers/speech_providers.dart';
import '../../speech/providers/tts_preferences_provider.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';

/// The Settings tab.
///
/// A profile card (name, what the learner is learning, streak; Edit opens a
/// sheet), then grouped cards: Appearance (app language, theme, colour —
/// each applies immediately, per docs/DESIGN_SYSTEM.md), Listening &
/// speaking (voice speed and pitch with a sample to hear them, microphone
/// access with an Allow button, speech-recognition availability), and Your
/// data (offline privacy, backup coming soon, and — last — reset
/// progress). The app version sits at the foot.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
          ),
          children: [
            Text(
              l10n.navSettings,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            const _ProfileCard(),
            SectionHeading(l10n.settingsAppearanceOverline),
            _Group(
              children: [
                _Block(
                  title: l10n.settingsInterfaceLanguageTitle,
                  subtitle: l10n.settingsLanguageBody,
                  child: const _InterfaceLanguagePicker(),
                ),
                _Block(
                  title: l10n.settingsThemeModeTitle,
                  child: const _ThemeModePicker(),
                ),
                _Block(
                  title: l10n.settingsColorThemeTitle,
                  child: const _ColorThemePicker(),
                ),
              ],
            ),
            SectionHeading(l10n.settingsSpeechTitle),
            _Group(
              children: [
                const _TtsRateBlock(),
                _Block(
                  title: l10n.settingsSpeechPitch,
                  child: const _TtsPitchSlider(),
                ),
                const _MicrophoneRow(),
                const _SpeechRecognitionRow(),
              ],
            ),
            SectionHeading(l10n.settingsDataOverline),
            _Group(
              children: [
                _Row(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.settingsOfflineTitle,
                  subtitle: l10n.settingsOfflineBody,
                ),
                _Row(
                  icon: Icons.cloud_sync_outlined,
                  title: l10n.settingsBackupTitle,
                  subtitle: l10n.settingsBackupBody,
                  trailing: StatusPill(label: l10n.comingSoon),
                ),
                const _ResetProgressRow(),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l10n.settingsVersion(kAppVersion),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// True when the screen is narrow for the text size — then a row's
/// trailing action goes under its text rather than squeezing it.
bool _isNarrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width /
        MediaQuery.textScalerOf(context).scale(1) <
    340;

/// A hairline card of settings, separated by dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            child,
          ],
        ],
      ),
    );
  }
}

/// A setting with its control under its title.
class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.md - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: AppSpace.sm - 2),
          child,
        ],
      ),
    );
  }
}

/// A one-line setting: icon, title, explanation, and an optional trailing
/// widget; tappable when [onTap] is set.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final accent = destructive ? theme.colorScheme.error : null;
    final narrow = _isNarrow(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md - 2),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: accent ?? tokens.textSecondary),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent ?? tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (trailing != null && narrow) ...[
                    const SizedBox(height: AppSpace.xs),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (trailing != null && !narrow) ...[
              const SizedBox(width: AppSpace.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A small outlined action inside a settings row ("Edit", "Allow").
class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
    );
    return icon == null
        ? OutlinedButton(style: style, onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

/// Who's learning: an initial, the name (or "Add your name"), what they're
/// learning and their streak; Edit opens a sheet to change the name.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  Future<void> _editName(BuildContext context, String? current) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NameSheet(initial: current ?? ''),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final learner = ref.watch(currentLearnerProvider).value;
    final streak = ref.watch(currentStreakDaysProvider).value ?? 0;
    // The profile line names the level the learner is in, not A1: this
    // card is the one place Settings says what they are studying.
    final levelId = ref.watch(currentLevelIdProvider).value;
    final levelCode = levelId == null
        ? null
        : levelCatalogEntryIn(
            ref.watch(levelCatalogProvider),
            levelId,
          )?.cefrCode;
    final meta = levelCode == null ? null : l10n.settingsProfileMeta(levelCode);
    final name = learner?.name?.trim();
    final hasName = name != null && name.isNotEmpty;
    final narrow = _isNarrow(context);
    final edit = _SmallAction(
      label: l10n.settingsEdit,
      icon: Icons.edit_outlined,
      onPressed: () => _editName(context, name),
    );

    return _Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.md - 2),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: tokens.primaryInkTint,
                  child: hasName
                      ? Text(
                          name.characters.first.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: tokens.primaryInk,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Icon(Icons.person_rounded, color: tokens.primaryInk),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? name : l10n.settingsNameEmpty,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasName
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switch ((meta, streak)) {
                        (final m?, > 0) =>
                          '$m · ${l10n.homeStreakChip(streak)}',
                        (final m?, _) => m,
                        (null, > 0) => l10n.homeStreakChip(streak),
                        _ => '',
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    if (narrow) ...[const SizedBox(height: AppSpace.xs), edit],
                  ],
                ),
              ),
              if (!narrow) ...[const SizedBox(width: AppSpace.xs), edit],
            ],
          ),
        ),
      ],
    );
  }
}

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet({required this.initial});

  final String initial;

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(learnerRepositoryProvider)
        .updateName(learnerId: learner.id, name: _controller.text.trim());
    ref.invalidate(currentLearnerProvider);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.settingsNameSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsNameTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.settingsNameHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _save,
            child: Text(l10n.settingsNameSaveButton),
          ),
        ],
      ),
    );
  }
}

class _InterfaceLanguagePicker extends ConsumerWidget {
  const _InterfaceLanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    return SegmentedButton<Locale>(
      showSelectedIcon: false,
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

    // Icon over label, scaled down to fit, so a label never breaks mid-word
    // on a narrow screen with large text.
    ButtonSegment<ThemeMode> segment(
      ThemeMode value,
      IconData icon,
      String label,
    ) => ButtonSegment(
      value: value,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs - 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ],
        ),
      ),
    );

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        segment(
          ThemeMode.light,
          Icons.light_mode_outlined,
          l10n.settingsThemeModeLight,
        ),
        segment(
          ThemeMode.dark,
          Icons.dark_mode_outlined,
          l10n.settingsThemeModeDark,
        ),
        segment(
          ThemeMode.system,
          Icons.brightness_auto_outlined,
          l10n.settingsThemeModeSystem,
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
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final selected = ref.watch(colorSeedPreferenceProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final narrow = _isNarrow(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final seed in AppColorSeed.values)
          Expanded(
            child: Semantics(
              button: true,
              selected: seed == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.control),
                onTap: () =>
                    ref.read(colorSeedPreferenceProvider.notifier).set(seed),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: seed == selected
                                ? tokens.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 18,
                            // The seed's *applied* accent, not the raw seed
                            // — see AppColorSeed.brandPrimary's doc comment.
                            // The picker must preview what selecting this
                            // theme actually produces.
                            backgroundColor: seed.brandPrimary,
                            child: seed == selected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: seed.onBrandPrimary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs - 2),
                      // Scales down rather than breaking a long word.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // On a narrow screen, one word per line first.
                          narrow
                              ? (isArabic ? seed.labelAr : seed.labelEn)
                                    .replaceAll(' ', '\n')
                              : (isArabic ? seed.labelAr : seed.labelEn),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: seed == selected
                                ? tokens.textPrimary
                                : tokens.textSecondary,
                            fontWeight: seed == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Voice speed, with a sample to hear it.
class _TtsRateBlock extends ConsumerWidget {
  const _TtsRateBlock();

  /// Spoken by Try it — ordinary A1 English, so the learner hears the
  /// voice as lessons use it.
  static const _sample = "Hello! I'm Maya. Nice to meet you.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rate = ref.watch(ttsRatePreferenceProvider);
    final pitch = ref.watch(ttsPitchPreferenceProvider);
    return _Block(
      title: l10n.settingsSpeechRate,
      trailing: _SmallAction(
        label: l10n.settingsTryVoice,
        icon: Icons.volume_up_rounded,
        onPressed: () => ref
            .read(textToSpeechServiceProvider)
            .speak(_sample, localeCode: 'en', rate: rate, pitch: pitch),
      ),
      child: _LabelledSlider(
        value: rate,
        min: 0.25,
        max: 1.0,
        low: l10n.settingsSlower,
        high: l10n.settingsFaster,
        onChanged: (v) => ref.read(ttsRatePreferenceProvider.notifier).set(v),
      ),
    );
  }
}

class _TtsPitchSlider extends ConsumerWidget {
  const _TtsPitchSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pitch = ref.watch(ttsPitchPreferenceProvider);
    return _LabelledSlider(
      value: pitch,
      min: 0.5,
      max: 2.0,
      low: l10n.settingsLower,
      high: l10n.settingsHigher,
      onChanged: (v) => ref.read(ttsPitchPreferenceProvider.notifier).set(v),
    );
  }
}

/// A slider with its two ends named under it.
class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String low;
  final String high;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final endStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(low, style: endStyle),
                Text(high, style: endStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Microphone access in plain words, with Allow when it can still be asked.
class _MicrophoneRow extends ConsumerWidget {
  const _MicrophoneRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final capabilities = ref.watch(currentSpeechCapabilitiesProvider).value;
    final status = capabilities?.micPermission;
    final canAsk =
        status == SpeechPermissionStatus.notDetermined ||
        status == SpeechPermissionStatus.denied;
    return _Row(
      icon: status == SpeechPermissionStatus.granted
          ? Icons.mic_none_rounded
          : Icons.mic_off_outlined,
      title: l10n.settingsMicTitle,
      subtitle: switch (status) {
        SpeechPermissionStatus.granted => l10n.settingsMicAllowed,
        SpeechPermissionStatus.denied => l10n.settingsMicDenied,
        SpeechPermissionStatus.permanentlyDenied => l10n.settingsMicBlocked,
        SpeechPermissionStatus.notDetermined || null => l10n.settingsMicNotYet,
      },
      trailing: canAsk
          ? _SmallAction(
              label: l10n.settingsMicAllow,
              onPressed: () async {
                await ref
                    .read(speechRecognitionServiceProvider)
                    .requestPermission();
                ref.invalidate(currentSpeechCapabilitiesProvider);
              },
            )
          : null,
    );
  }
}

class _SpeechRecognitionRow extends ConsumerWidget {
  const _SpeechRecognitionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final available =
        ref
            .watch(currentSpeechCapabilitiesProvider)
            .value
            ?.sttAvailableForLocale ??
        false;
    return _Row(
      icon: Icons.record_voice_over_outlined,
      title: l10n.settingsSttTitle,
      subtitle: available ? l10n.settingsSttOn : l10n.settingsSttOff,
    );
  }
}

/// The last setting on the page: erase this learner's progress, after a
/// confirmation. The learner row itself survives.
class _ResetProgressRow extends ConsumerWidget {
  const _ResetProgressRow();

  Future<void> _confirmAndReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.restart_alt_rounded, color: colorScheme.error),
          title: Text(l10n.settingsResetProgressConfirmTitle),
          content: Text(l10n.settingsResetProgressConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.settingsResetProgressCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsResetProgressConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    final learner = await ref.read(currentLearnerProvider.future);
    await db.resetProgressForLearner(learner.id);

    ref.invalidate(allUnitProgressProvider);
    ref.invalidate(allLessonProgressProvider);
    ref.invalidate(allVocabularyReviewStateProvider);
    ref.invalidate(allGrammarReviewStateProvider);
    ref.invalidate(reviewContentProvider);
    ref.invalidate(weakSpotsProvider);
    ref.invalidate(dueVocabularyProvider);
    ref.invalidate(currentLevelIdProvider);
    // A family: invalidating the family itself clears every already-built
    // levelId's enrolment-ensure state, matching the wipe below.
    ref.invalidate(ensureLevelEnrolmentProvider);
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
    return _Row(
      icon: Icons.restart_alt_rounded,
      title: l10n.settingsResetProgressTitle,
      subtitle: l10n.settingsResetProgressBody,
      destructive: true,
      trailing: _isNarrow(context)
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).extension<AppTokens>()!.textSecondary,
            ),
      onTap: () => _confirmAndReset(context, ref),
    );
  }
}
