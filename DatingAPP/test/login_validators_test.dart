import 'package:dating_app/features/login/data/phone_countries.dart';
import 'package:dating_app/features/login/validators/login_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone rejects missing country-specific digits', () {
    final india = PhoneCountries.all.first;
    expect(LoginValidators.phone('', india), isNotNull);
    expect(LoginValidators.phone('123', india), isNotNull);
    expect(LoginValidators.phone('9876543210', india), isNull);
    expect(LoginValidators.phone('+919876543210', india), isNotNull);
    final australia = PhoneCountries.all[3];
    expect(LoginValidators.phone('412345678', australia), isNull);
    expect(LoginValidators.phone('0412345678', australia), isNotNull);
  });
  test('verification accepts exactly six digits', () {
    expect(LoginValidators.code('123456'), isNull);
    expect(LoginValidators.code('12345'), isNotNull);
    expect(LoginValidators.code('abcdef'), isNotNull);
    expect(LoginValidators.code('1234567'), isNotNull);
  });
}
