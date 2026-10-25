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

  final authenticatedFullName = authenticatedUser.fullname.trim().isNotEmpty
      ? authenticatedUser.fullname.trim()
      : authenticatedUser.username.trim();
  final authenticatedEmail = authenticatedUser.email.trim();
  final authenticatedUsername = authenticatedUser.username.trim();

  // If the account belongs to a different email, do not retain previous user's state.
  final isSameUserAccount =
      account.email.trim().isEmpty ||
      account.email.trim().toLowerCase() == authenticatedEmail.toLowerCase();

  final baseAccount = isSameUserAccount ? account : ProfileAccount.empty();
  final accountName = baseAccount.name.trim();

  // If accountName is a valid non-placeholder and not simply the raw username, keep it;
  // otherwise prioritize the authenticated user's full name.
  final isAccountNameValidFullName =
      accountName.isNotEmpty &&
      accountName.toLowerCase() != 'anonymous user' &&
      accountName.toLowerCase() != authenticatedUsername.toLowerCase();

  final resolvedName = isAccountNameValidFullName
      ? accountName
      : (authenticatedFullName.isNotEmpty
            ? authenticatedFullName
            : authenticatedUsername);

  final resolvedEmail = authenticatedEmail.isNotEmpty
      ? authenticatedEmail
      : baseAccount.email.trim();

  final resolvedUsername = authenticatedUsername.isNotEmpty
      ? authenticatedUsername
      : baseAccount.username.trim();

  final avatar = authenticatedUser.avatarUrl.trim().isNotEmpty
      ? authenticatedUser.avatarUrl.trim()
      : (baseAccount.avatarUrl?.trim().isNotEmpty == true
            ? baseAccount.avatarUrl!.trim()
            : null);

  final resolvedPhone = authenticatedUser.phone.trim().isNotEmpty
      ? authenticatedUser.phone.trim()
      : baseAccount.phoneNumber.trim();

  return baseAccount.copyWith(
    name: resolvedName,
    email: resolvedEmail,
    username: resolvedUsername,
    avatarUrl: avatar,
    phoneNumber: resolvedPhone,
  );
}
