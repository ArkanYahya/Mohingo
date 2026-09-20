/// Normalizes a bundle field that's meant to be an optional string: `null`
/// for anything that isn't really "given" — a non-String value, or a
/// String that's empty or whitespace-only — and [value] itself otherwise.
///
/// Several registry/curriculum/activity fields are optional strings the
/// bundle sometimes writes as `""` rather than omitting; treating a blank
/// string as "not given" keeps every reader of these fields from having to
/// re-derive that rule (and from a blank value silently shadowing a real
/// one — see `TextChoiceActivity.sourceText`).
String? nonBlank(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
