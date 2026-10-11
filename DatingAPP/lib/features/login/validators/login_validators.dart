import '../models/phone_country.dart';

abstract final class LoginValidators {
  static String? phone(String? value, PhoneCountry country) {
    final digits = value?.trim() ?? '';
    if (digits.isEmpty) return 'Enter your phone number.';
    if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Use digits only.';
    if (country.nationalLength != null &&
        digits.length != country.nationalLength) {
      return 'Enter a ${country.nationalLength}-digit number without the country code.';
    }
    if (digits.length < 7 || digits.length + country.dialCode.length - 1 > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? code(String? value) =>
      RegExp(r'^\d{6}$').hasMatch(value ?? '') ? null : 'Enter all 6 digits.';
}
