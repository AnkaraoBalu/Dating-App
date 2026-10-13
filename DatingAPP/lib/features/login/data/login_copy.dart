/// User-facing copy shared by the authentication screens.
abstract final class LoginCopy {
  static const brandAgreement = 'By continuing, you agree to our';
  static const terms = 'Terms';
  static const privacyPolicy = 'Privacy Policy';
  static const termsUnavailable =
      'Our terms are not published yet. Please check back soon.';
  static const privacyUnavailable =
      'Our privacy policy is not published yet. Please check back soon.';

  static const enterEmail = 'Sign in with email';
  static const enterPhone = 'Enter your number';
  static const createAccount = 'Create your account';
  static const verificationTitle = 'Verify your';
  static const verificationSubtitle = 'Enter the 6-digit code sent to';
  static const sendCode = 'Send verification code';
  static const verifyCode = 'Verify code';
  static const resendCode = 'Resend code';
  static const emailHint = 'you@example.com';
  static const phoneHint = '98765 43210';
  static const emailLabel = 'Email address';
  static const phoneLabel = 'Phone number';
  static const newToJust2 = 'New to Just2? Create account';
  static const existingAccount = 'Already have an account? Sign in';

  static String resendCodeIn(int seconds) =>
      'Resend code in 00:${seconds.toString().padLeft(2, '0')}';
}
