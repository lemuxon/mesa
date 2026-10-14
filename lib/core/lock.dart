import 'package:local_auth/local_auth.dart';

/// Kimlik doğrulama: parmak izi / yüz tanıma, yoksa ekran kilidi (PIN, desen).
/// Testlerde sahtesiyle değiştirilebilsin diye soyut.
abstract class Authenticator {
  /// Cihazda biyometri ya da ekran kilidi tanımlı mı.
  Future<bool> isAvailable();

  /// Doğrulandıysa true; iptal ya da hata: false.
  Future<bool> authenticate(String reason);
}

class DeviceAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Biyometri yoksa ya da başarısızsa ekran kilidiyle de açılabilsin.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
