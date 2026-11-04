import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

ProfileAccount _account(String name) =>
    ProfileAccount(name: name, email: 'a@b.co', timezone: 'Africa/Lagos');

OrganizationProfile _organization(String name) => OrganizationProfile(
  id: 'org-1',
  name: name,
  natureOfBusiness: '',
  country: '',
);

void main() {
  group('ProfileAccount.initials', () {
    test('uses the first and last name', () {
      expect(_account('Ada Lovelace').initials, 'AL');
    });

    test('uses one letter for a single name', () {
      expect(_account('ada').initials, 'A');
    });

    test('falls back for a blank name', () {
      expect(_account('  ').initials, 'ZU');
    });

    test('keeps a single emoji name whole', () {
      expect(_account('😀').initials, '😀');
    });

    test('keeps a leading flag whole', () {
      expect(_account('🇳🇬 Ada').initials, '🇳🇬A');
    });

    test('keeps an emoji at the start of either name whole', () {
      expect(_account('😀 Smith').initials, '😀S');
      expect(_account('Ada 😀').initials, 'A😀');
    });
  });

  group('OrganizationProfile.initials', () {
    test('uses the first and last word', () {
      expect(_organization('HNG Internship').initials, 'HI');
    });

    test('uses one letter for a single word', () {
      expect(_organization('zedu').initials, 'Z');
    });

    test('falls back for a blank name', () {
      expect(_organization('').initials, 'ZO');
    });

    test('keeps a single emoji name whole', () {
      expect(_organization('🚀').initials, '🚀');
    });

    test('keeps an emoji at the start of either word whole', () {
      expect(_organization('🚀 Labs').initials, '🚀L');
      expect(_organization('Moon 🌙').initials, 'M🌙');
    });
  });
}
