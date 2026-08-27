import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:qitianxuetang/services/qitian_crypto.dart';

void main() {
  group('QitianCrypto', () {
    test('密码加密与抓包算法一致（base64(明文+常量后缀)）', () {
      // 常量后缀，与用户名/手机号无关，硬编码于算法中
      const suffix = '{MTgyMjU2MDU0MjF7c3pvbmV9}';
      const plain = 'abc';
      const expected = 'YWJje01UZ3lNalUyTURVME1qRjdjM3B2Ym1WOX0=';
      expect(QitianCrypto.encryptPassword(plain), expected);
      expect(QitianCrypto.encryptPassword(plain),
          base64.encode(utf8.encode(plain + suffix)));
    });

    test('AES-256-ECB 加解密往返', () {
      const plain = '{"msg":"hi 七天"}';
      final enc = _aesEncode(plain);
      expect(QitianCrypto.aesEcbDecryptBase64(enc), plain);
    });
  });
}

String _aesEncode(String plain) {
  final key = Uint8List.fromList(utf8.encode('c0f1a30cba2147949ee71cf71cba3c20'));
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
  final data = utf8.encode(plain);
  final n = (data.length ~/ 16 + 1) * 16;
  final padded = Uint8List(n);
  padded.setAll(0, data);
  final pad = n - data.length;
  for (var i = data.length; i < n; i++) {
    padded[i] = pad;
  }
  final out = Uint8List(n);
  for (var i = 0; i < n; i += 16) {
    cipher.processBlock(padded, i, out, i);
  }
  return base64.encode(out);
}