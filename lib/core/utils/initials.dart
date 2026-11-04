import 'package:flutter/widgets.dart';

/// The first character a person sees in [text], uppercased, for an avatar
/// initial. Returns [fallback] when [text] is null or blank.
///
/// This takes a whole user-perceived character, not `text[0]`: that is one
/// UTF-16 code unit, which cuts an emoji, a flag or an accented letter in
/// half and renders a broken glyph.
String firstCharacter(String? text, {String fallback = '?'}) {
  final trimmed = text?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;
  return trimmed.characters.first.toUpperCase();
}
