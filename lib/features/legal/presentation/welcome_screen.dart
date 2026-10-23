import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/locale_preference_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/section_heading.dart';
import '../domain/legal_documents.dart';
import '../providers/agreement_providers.dart';

/// The first screen of a fresh install, and the screen a learner meets
/// again only when the agreement's version is raised ([kAgreementVersion]).
///
/// It says what Mohingo is and, in four plain points, what stays on the
/// phone and what can leave it — the same facts as the full privacy policy,
/// which is one tap away with the terms. "Accept and continue" records the
/// accepted version; the router then opens the app. The interface language
/// can be switched here, before anything else is read. See
/// docs/adr/0011-first-run-agreement-app-guide-and-account-deletion.md.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final previouslyAccepted = ref.watch(acceptedAgreementVersionProvider) > 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.md,
                ),
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _LanguageSwitch(),
                  ),
                  const SizedBox(height: AppSpace.md),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BrandMark(),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.welcomeTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.welcomeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (previouslyAccepted) ...[
                    const SizedBox(height: AppSpace.md),
                    _UpdatedNotice(text: l10n.welcomeUpdatedNotice),
                  ],
                  SectionHeading(l10n.welcomePrivacyHeading),
                  _PointsCard(
                    points: [
                      _Point(
                        icon: Icons.smartphone_rounded,
                        title: l10n.welcomeLocalTitle,
                        body: l10n.welcomeLocalBody,
                      ),
                      _Point(
                        icon: Icons.cloud_outlined,
                        title: l10n.welcomeAccountTitle,
                        body: l10n.welcomeAccountBody,
                      ),
                      _Point(
                        icon: Icons.spellcheck_rounded,
                        title: l10n.welcomeWritingTitle,
                        body: l10n.welcomeWritingBody,
                      ),
                      _Point(
                        icon: Icons.mic_none_rounded,
                        title: l10n.welcomeSpeechTitle,
                        body: l10n.welcomeSpeechBody,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: AppSpace.xs,
                    children: [
                      _DocumentLink(
                        label: l10n.legalPrivacyTitle,
                        document: LegalDocument.privacy,
                      ),
                      _DocumentLink(
                        label: l10n.legalTermsTitle,
                        document: LegalDocument.terms,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.page,
                border: Border(top: BorderSide(color: tokens.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.welcomeConsentLine,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => ref
                          .read(acceptedAgreementVersionProvider.notifier)
                          .acceptCurrent(),
                      child: Text(l10n.welcomeAccept),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arabic or English, each named in its own script, so a learner can read
/// this screen in their language before accepting anything.
class _LanguageSwitch extends ConsumerWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: 'ar', label: Text('العربية')),
        ButtonSegment(value: 'en', label: Text('English')),
      ],
      selected: {locale.languageCode},
      onSelectionChanged: (selection) => ref
          .read(localePreferenceProvider.notifier)
          .set(Locale(selection.first)),
    );
  }
}

class _UpdatedNotice extends StatelessWidget {
  const _UpdatedNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.primaryInkTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.info_outline_rounded, color: tokens.primaryInk),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});

  final List<_Point> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          for (final (i, point) in points.indexed) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md - 2),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: tokens.primaryInkTint,
                        child: Icon(
                          point.icon,
                          size: 20,
                          color: tokens.primaryInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            point.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentLink extends StatelessWidget {
  const _DocumentLink({required this.label, required this.document});

  final String label;
  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () => context.push('/legal/${document.slug}'),
      icon: const Icon(Icons.description_outlined, size: 18),
      label: Text(label),
    );
  }
}
