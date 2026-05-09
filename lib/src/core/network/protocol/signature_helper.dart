import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class SignatureHelper {
  const SignatureHelper._();

  static String generate({
    required Map<String, dynamic> params,
    required String secret,
  }) {
    final keys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write(key);
      buffer.write('${params[key] ?? ''}');
    }
    final digest = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(buffer.toString()));
    return digest.toString();
  }

  static String randomDigits({int length = 8}) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }
}
