import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  EncryptionHelper({required String key, required String iv})
    : _key = encrypt.Key.fromUtf8(key),
      _iv = encrypt.IV.fromUtf8(iv);

  final encrypt.Key _key;
  final encrypt.IV _iv;

  String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptText(String cipherText) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.decrypt64(cipherText, iv: _iv);
  }
}
