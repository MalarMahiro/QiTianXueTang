import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 七天学堂「会话级安全加密」工具
///
/// Ponytail: 从原 APK `LocalAesCryptoUtil` + `septnetlive` 插件逆向。
/// 机制(仅用于带 `bn`(iv) 字段的 isEncrypt 接口，如 GetUserInfo)：
///  1. App 端用 SecureRandom 生成一把随机会话 AES-256 key(32字节)，仅存内存。
///  2. 用硬编码 RSA公钥对该 key 做 RSA/ECB/PKCS1Padding 加密 → base64 = `bk`。
///  3. `POST szone-my/user` 空body、header `bk` 与服务器协商绑定。
///  4. 后续 isEncrypt 接口请求带 `bk` 头；响应体 `data` = {isEncrypt, bn(iv), content(密文)}，
///     用 `encryptKey + bn(iv)` 做 AES-GCM/NoPadding 解密 content。
///  5. content = base64(ciphertext + 16字节GCM tag)。
class SecureCrypto {
  SecureCrypto._();

  /// 逆向得到的服务器 RSA 公钥 (base64, X509 SubjectPublicKeyInfo)
  static const String rsaPublicKeyB64 =
      'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDrjEcFVWu6mizSyP3fCCaWZ3BeTeuZx44HHcWhzq6+FkueApOJbifi0VfaUO6S9eHvaJSEaCUFouD3cxr3fOk8RYQw1S1BcTscEbnqq/PCuoj5vj12t/M3dbqTdNKCrufSukwBask+OOHenu9IJzkmvrPurLnIC3yDTy3Ix9YliQIDAQAB';

  /// 当前会话 AES key(base64)。随会话随机生成，与协商绑定。
  static String? _aesKeyBase64;

  static bool get hasKey => _aesKeyBase64 != null;

  /// 生成随机会话 AES key 并返回（base64 字符串）。可重复调用刷新。
  static String generateSessionKey() {
    final rnd = FortunaRandom()..seed(KeyParameter(_randomBytes(32)));
    final keyBytes = rnd.generateRandom(32).toUint8List();
    _aesKeyBase64 = base64.encode(keyBytes);
    return _aesKeyBase64!;
  }

  static Uint8List _randomBytes(int len) {
    final rnd = FortunaRandom()..seed(KeyParameter(Uint8List(32)));
    return rnd.generateRandom(len).toUint8List();
  }

  /// 从 DER SubjectPublicKeyInfo 线性遍历，提取 RSA modulus(n) 和 publicExponent(e)。
  /// 该结构中仅有两个 INTEGER：n 和 e。
  static RSAPublicKey _publicKey() {
    final der = base64.decode(rsaPublicKeyB64);
    BigInt? n, e;
    var p = 0;
    while (p + 1 < der.length) {
      final tag = der[p];
      var len = der[p + 1];
      var vs = p + 2;
      if (len == 0x81) {
        len = der[p + 2];
        vs = p + 3;
      } else if (len == 0x82) {
        len = (der[p + 2] << 8) | der[p + 3];
        vs = p + 4;
      }
      if (tag == 0x02) {
        var start = vs;
        var l = len;
        if (l > 0 && der[vs] == 0) {
          start = vs + 1;
          l -= 1;
        }
        var hex = StringBuffer();
        for (var i = start; i < start + l; i++) {
          hex.write(der[i].toRadixString(16).padLeft(2, '0'));
        }
        final big = BigInt.parse(hex.toString(), radix: 16);
        if (n == null) {
          n = big;
        } else if (e == null) {
          e = big;
        }
      }
      p = vs + len;
    }
    if (n == null || e == null) {
      throw StateError('RSA公钥解析失败: 未找到 n/e');
    }
    return RSAPublicKey(n, e);
  }

  /// 生成协商头 `bk` = RSA 公钥加密(会话key的base64字符串)。
  static String buildBk() {
    if (_aesKeyBase64 == null) generateSessionKey();
    final pk = _publicKey();
    final cipher = PKCS1Encoding(RSAEngine())..init(true, PublicKeyParameter(pk));
    final data = utf8.encode(_aesKeyBase64!);
    final out = cipher.process(data);
    return base64.encode(out);
  }

  /// AES-GCM 解密：key=会话key，iv=响应bn(base64,12字节)，content=base64(ciphertext+16字节tag)。
  /// 返回解密后的明文字符串(JSON)。
  static String aesGcmDecrypt(String contentB64, String ivB64) {
    if (_aesKeyBase64 == null) {
      throw StateError('会话AES key未初始化，请先协商(buildBk/POST /user)');
    }
    final keyBytes = base64.decode(_aesKeyBase64!);
    final iv = base64.decode(ivB64);
    final raw = base64.decode(contentB64);
    // GCM: 密文最后16字节是认证标签
    final tag = Uint8List.sublistView(raw, raw.length - 16);
    final ciph = Uint8List.sublistView(raw, 0, raw.length - 16);

    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(keyBytes),
          128, // tag长度(bit)
          iv,
          Uint8List(0), // AAD空
        ),
      );
    final out = Uint8List(gcm.getOutputSize(ciph.length));
    final n = gcm.processBytes(ciph, 0, ciph.length, out, 0);
    gcm.doFinal(out, n);
    return utf8.decode(out, allowMalformed: true);
  }
}