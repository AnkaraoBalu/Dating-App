import '../models/phone_country.dart';

abstract final class PhoneCountries {
  static const all = [
    PhoneCountry('India', '+91', nationalLength: 10),
    PhoneCountry('United States / Canada', '+1', nationalLength: 10),
    PhoneCountry('United Kingdom', '+44', nationalLength: 10),
    PhoneCountry('Australia', '+61', nationalLength: 9),
    PhoneCountry('United Arab Emirates', '+971', nationalLength: 9),
  ];
}
