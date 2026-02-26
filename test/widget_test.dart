import 'package:flutter_test/flutter_test.dart';
import 'package:omnisource/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email validator accepts a valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('email validator rejects invalid email', () {
      expect(Validators.email('invalid-email'), isNotNull);
    });

    test('password validator accepts strong password', () {
      expect(Validators.password('StrongPass1!'), isNull);
    });

    test('password validator rejects weak password', () {
      expect(Validators.password('weak'), isNotNull);
    });
  });
}
