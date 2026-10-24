import 'package:zedu/features/auth/domain/entities/user.dart';

class ProfileAccount {
  const ProfileAccount({
    required this.name,
    required this.email,
    required this.timezone,
    this.avatarUrl,
    this.displayName = '',
    this.username = '',
    this.phoneNumber = '',
    this.title = '',
    this.namePronunciation = '',
    this.country = '',
  });

  factory ProfileAccount.empty() =>
      const ProfileAccount(name: '', email: '', timezone: 'Africa/Lagos');

  final String name;
  final String email;
  final String timezone;
  final String? avatarUrl;
  final String displayName;
  final String username;
  final String phoneNumber;
  final String title;
  final String namePronunciation;
  final String country;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'ZU';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  ProfileAccount copyWith({
    String? name,
    String? email,
    String? timezone,
    String? avatarUrl,
    String? displayName,
    String? username,
    String? phoneNumber,
    String? title,
    String? namePronunciation,
    String? country,
  }) {
    return ProfileAccount(
      name: name ?? this.name,
      email: email ?? this.email,
      timezone: timezone ?? this.timezone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      title: title ?? this.title,
      namePronunciation: namePronunciation ?? this.namePronunciation,
      country: country ?? this.country,
    );
  }
}

ProfileAccount accountForAuthenticatedUser(
  ProfileAccount account,
  User? authenticatedUser,
) {
  if (authenticatedUser == null) return account;

  final authenticatedName = authenticatedUser.fullname.trim().isNotEmpty
      ? authenticatedUser.fullname.trim()
      : authenticatedUser.username;
  final name = account.name.trim();
  final email = account.email.trim();

  return account.copyWith(
    name: name.isEmpty || name.toLowerCase() == 'anonymous user'
        ? authenticatedName
        : name,
    email: email.isEmpty || email.toLowerCase() == 'anonymoususer@email.com'
        ? authenticatedUser.email
        : email,
    username:
        account.username.trim().isEmpty ||
            account.username.toLowerCase() == 'anonymoususer'
        ? authenticatedUser.username
        : account.username,
    avatarUrl: account.avatarUrl?.trim().isNotEmpty == true
        ? account.avatarUrl
        : authenticatedUser.avatarUrl,
  );
}
