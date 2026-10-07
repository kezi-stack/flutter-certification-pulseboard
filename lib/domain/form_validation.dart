String? validateName(String value) =>
    value.trim().length >= 2 ? null : 'nameTooShort';

String? validateUsername(String value) =>
    value.trim().length >= 3 ? null : 'usernameTooShort';

String? validatePassword(String value) =>
    value.length >= 8 ? null : 'passwordTooShort';

String? validateEmail(String value) {
  final email = value.trim();
  final at = email.indexOf('@');
  final dot = email.lastIndexOf('.');
  return at > 0 && dot > at + 1 && dot < email.length - 1
      ? null
      : 'invalidEmail';
}
