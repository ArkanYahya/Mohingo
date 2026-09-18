/// Where an old Learn-tab address now lives, or null if [uri] is current.
///
/// The Learn tab used to open on a level list (`/learn`), with each level's
/// path at `/learn/<level>` and its units at `/learn/<level>/unit/<id>`. It
/// now opens straight on the course and units live at `/learn/unit/<id>`,
/// so a saved or deep link to the old shape — including a not-yet-available
/// level — still lands somewhere sensible.
String? legacyLearnRedirect(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.isEmpty || segments.first != 'learn') return null;
  if (segments.length < 2 || segments[1] == 'unit') return null;
  if (segments.length >= 4 && segments[2] == 'unit') {
    return '/learn/unit/${segments[3]}';
  }
  return '/learn';
}
