import 'package:certificat/domain/form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateName', () {
    test('accepts a name with at least two non-space characters', () {
      expect(validateName(' Al '), isNull);
    });

    test('rejects an empty or one-character name', () {
      expect(validateName('  '), 'nameTooShort');
      expect(validateName('A'), 'nameTooShort');
    });
  });

  group('validateUsername', () {
    test('trims surrounding spaces before checking the minimum length', () {
      expect(validateUsername(' alice '), isNull);
      expect(validateUsername(' ab '), 'usernameTooShort');
    });
  });

  group('validatePassword', () {
    test('accepts passwords of eight or more characters', () {
      expect(validatePassword('12345678'), isNull);
      expect(validatePassword('longer-password'), isNull);
    });

    test('rejects passwords shorter than eight characters', () {
      expect(validatePassword('1234567'), 'passwordTooShort');
    });
  });

  group('validateEmail', () {
    test('accepts a basic email address', () {
      expect(validateEmail(' person@example.org '), isNull);
    });

    test('rejects missing local part, domain, or top-level domain', () {
      expect(validateEmail('@example.org'), 'invalidEmail');
      expect(validateEmail('person@'), 'invalidEmail');
      expect(validateEmail('person@example'), 'invalidEmail');
    });
  });
}
