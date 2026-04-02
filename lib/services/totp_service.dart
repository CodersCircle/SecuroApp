import 'package:otp/otp.dart';

class TotpService {
  TotpService._();
  static final TotpService instance = TotpService._();

  /// Generate TOTP code from secret key
  String generateCode(String secret, {int digits = 6, int period = 30}) {
    try {
      return OTP.generateTOTPCodeString(
        secret.toUpperCase().replaceAll(' ', ''),
        DateTime.now().millisecondsSinceEpoch,
        length: digits,
        interval: period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (_) {
      return '------';
    }
  }

  /// Format 6-digit code as "123 456"
  String formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  /// Seconds remaining in current period
  int secondsRemaining({int period = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  /// Parse otpauth URI from QR code
  /// Format: otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
  Map<String, String>? parseOtpAuthUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.scheme != 'otpauth' || parsed.host != 'totp') return null;

      final secret = parsed.queryParameters['secret'] ?? '';
      final issuerParam = parsed.queryParameters['issuer'] ?? '';
      final pathParts = parsed.path.replaceFirst('/', '').split(':');

      final issuer = issuerParam.isNotEmpty
          ? issuerParam
          : (pathParts.length > 1 ? pathParts[0] : 'Unknown');
      final account = pathParts.last;

      return {'secret': secret, 'issuer': issuer, 'account': account};
    } catch (_) {
      return null;
    }
  }
}
