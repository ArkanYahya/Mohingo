import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/catalog/level_catalog.dart';
import '../../content/index/course_content_index.dart';
import '../../content/providers/course_content_providers.dart';
import '../../features/legal/providers/agreement_providers.dart';

/// Bridges the base level's ([kBaseLevelId]) [courseContentProvider]
/// `AsyncValue` changes into a [Listenable] so `GoRouter`'s `redirect`
/// re-evaluates the moment content finishes loading (or fails) —
/// otherwise a redirect decided once at the initial "loading" state would
/// never be revisited. See docs/ARCHITECTURE.md's content-loading
/// strategy. Also re-evaluates when the first-run agreement is accepted.
class ContentLoadRefreshListenable extends ChangeNotifier {
  ContentLoadRefreshListenable(Ref ref) {
    ref.listen<AsyncValue<CourseContentIndex>>(
      courseContentProvider(kBaseLevelId),
      (previous, next) => notifyListeners(),
    );
    // Accepting the first-run agreement moves the learner on from
    // /welcome the same way.
    ref.listen<bool>(
      agreementAcceptedProvider,
      (previous, next) => notifyListeners(),
    );
  }
}
