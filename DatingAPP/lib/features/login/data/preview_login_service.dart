import '../models/verification_challenge.dart';

/// UI-only adapter: never sends SMS, stores tokens, or creates an account.
class PreviewLoginService {
  const PreviewLoginService();
  static const code = '123456';

  Future<VerificationChallenge> requestCode(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return VerificationChallenge(phoneNumber: phoneNumber, previewCode: code);
  }

  Future<bool> verify(VerificationChallenge challenge, String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value == challenge.previewCode;
  }
}
