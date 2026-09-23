import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_info.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../legal/domain/legal_documents.dart';

/// A personal dedication, shown at the foot of About.
///
/// Deliberately English in both interface languages and deliberately not an
/// ARB string: it is the author's own sentence and is never translated.
/// Always laid out left-to-right, so the Arabic interface shows it exactly
/// as written.
const kAboutDedication =
    'Inspired by Mohammed Faris — the reason this journey began';

/// About Mohingo: the app's identity and version (read from the installed
/// package — pubspec.yaml's `version:` is the only place it is set), the
/// privacy policy, the terms, the open-source licences, and the dedication.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appPackageInfoProvider).value?.version;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.md,
            AppSpace.md,
            AppSpace.xl,
          ),
          children: [
            const Center(child: BrandMark(size: 88)),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Mohingo',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              version == null ? '' : l10n.aboutVersion(version),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.aboutDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Material(
              color: tokens.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: tokens.border),
              ),
              child: Column(
                children: [
                  _AboutRow(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.legalPrivacyTitle,
                    subtitle: l10n.aboutPrivacyBody,
                    onTap: () =>
                        context.push('/legal/${LegalDocument.privacy.slug}'),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _AboutRow(
                    icon: Icons.description_outlined,
                    title: l10n.legalTermsTitle,
                    subtitle: l10n.aboutTermsBody,
                    onTap: () =>
                        context.push('/legal/${LegalDocument.terms.slug}'),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _AboutRow(
                    icon: Icons.code_rounded,
                    title: l10n.aboutLicensesTitle,
                    subtitle: l10n.aboutLicensesBody,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Mohingo',
                      applicationVersion: version,
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(AppSpace.xs),
                        child: BrandMark(size: 56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const _Dedication(),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpace.md - 2,
        end: AppSpace.xs,
      ),
      leading: Icon(icon, color: tokens.textSecondary),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
      onTap: onTap,
    );
  }
}

/// The name inside [kAboutDedication], set in the accent colour.
const _dedicationName = 'Mohammed Faris';

/// [kAboutDedication] as a small keepsake card: a soft accent-tinted
/// surface, a heart, and the sentence with the name picked out — noticeable
/// without turning into a banner. The sentence itself is never altered;
/// only its name is styled.
class _Dedication extends StatelessWidget {
  const _Dedication();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final base = theme.textTheme.titleMedium?.copyWith(
      color: tokens.textPrimary,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      height: 1.45,
    );
    final nameAt = kAboutDedication.indexOf(_dedicationName);
    final nameEnd = nameAt + _dedicationName.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: tokens.primaryInk.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [tokens.primaryInkTint, tokens.card],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
        ),
        child: Column(
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.card,
                  border: Border.all(color: tokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 22,
                    color: tokens.primaryInk,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // Always left-to-right, and read aloud in English, as written.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: nameAt < 0
                      ? [const TextSpan(text: kAboutDedication)]
                      : [
                          TextSpan(text: kAboutDedication.substring(0, nameAt)),
                          TextSpan(
                            text: _dedicationName,
                            style: TextStyle(
                              color: tokens.primaryInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: kAboutDedication.substring(nameEnd)),
                        ],
                ),
                textAlign: TextAlign.center,
                locale: const Locale('en'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
