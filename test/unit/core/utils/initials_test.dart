import 'dart:convert';

import 'package:zedu/core/core.dart';
import '../../../helpers/helpers.dart';

void main() {
  group('firstCharacter', () {
    test('uppercases the first letter', () {
      expect(firstCharacter('ada'), 'A');
    });

    test('keeps an emoji whole', () {
      expect(firstCharacter('😀 Smile'), '😀');
    });

    test('keeps a flag whole', () {
      expect(firstCharacter('🇳🇬 Naija'), '🇳🇬');
    });

    test('keeps a joined emoji sequence whole', () {
      expect(firstCharacter('👨‍👩‍👧 Family'), '👨‍👩‍👧');
    });

    test('keeps a letter with a combining accent whole', () {
      expect(firstCharacter('élan'), 'É');
    });

    test('keeps a character outside the basic plane whole', () {
      expect(firstCharacter('𝒜da'), '𝒜');
    });

    test('ignores leading whitespace', () {
      expect(firstCharacter('  ada '), 'A');
    });

    test('falls back for null, empty and blank text', () {
      expect(firstCharacter(null), '?');
      expect(firstCharacter(''), '?');
      expect(firstCharacter('   '), '?');
    });

    test('uses the given fallback', () {
      expect(firstCharacter('', fallback: 'ZU'), 'ZU');
    });

    test('never returns half of a surrogate pair', () {
      for (final name in ['😀', '🇳🇬', '𝒜', '👨‍👩‍👧']) {
        final initial = firstCharacter(name);
        // A lone surrogate is replaced by U+FFFD when encoded, so a whole
        // character survives the round trip and half of one does not.
        expect(utf8.decode(utf8.encode(initial)), initial);
        expect(initial, name);
      }
    });
  });
}
