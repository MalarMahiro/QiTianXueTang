import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 七天学堂「会话级安全加密」工具
///
/// Ponytail: 从原 APK `LocalAesCryptoUtil` + `septnetlive` 插件逆向。
/// 机制(仅用于带 `bn`(iv) 字段的 isEncrypt 接口，如 GetUserInfo)：
///  1. App 端生成一把随机会话 AES-256 key(32字节)。
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
    _aesKeyBase64 = base64.encode(_randomBytes(32));
    return _aesKeyBase64!;
  }

  static Uint8List _randomBytes(int len) {
    // 用 dart:math 的加密安全随机源
    final rnd = Random.secure();
    final buf = Uint8List(len);
    for (var i = 0; i < len; i++) {
      buf[i] = rnd.nextInt(256);
    }
    return buf;
  }

  /// 从 DER SubjectPublicKeyInfo 递归解析，提取 RSA modulus(n) 和 publicExponent(e)。
  /// 结构: SEQUENCE{ SEQUENCE{OID,NULL}, BIT STRING{ 0x00, SEQUENCE{ INTEGER(n), INTEGER(e) } } }
  static RSAPublicKey _publicKey() {
    final der = base64.decode(rsaPublicKeyB64);
    final ints = <BigInt>[];
    // 递归遍历 DER TLV，收集所有 INTEGER(0x02)
    void walk(int p, int end) {
      while (p + 1 < end) {
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
        if (vs + len > end) return; // 越界保护
        if (tag == 0x02) {
          // INTEGER：跳过可能的前导0x00
          var start = vs;
          var l = len;
          if (l > 0 && der[vs] == 0) {
            start = vs + 1;
            l -= 1;
          }
          final big = Uint8List.fromList(der.sublist(start, start + l))
              .fold(BigInt.zero, (acc, b) => (acc << 8) | BigInt.from(b));
          ints.add(big);
        } else if (tag == 0x03) {
          // BIT STRING: 内容首字节是unused-bits数，之后是内嵌SEQUENCE{INTEGER n, INTEGER e}
          walk(vs + 1, vs + len);
        } else if (tag == 0x30 || tag == 0x31) {
          // SEQUENCE/SET：递归深入
          walk(vs, vs + len);
        }
        p = vs + len;
      }
    }

    walk(0, der.length);
    if (ints.length < 2) {
      throw StateError('RSA公钥解析失败: 未找到 n/e (found ${ints.length})');
    }
    return RSAPublicKey(ints[0], ints[1]);
  }

  /// 生成协商头 `bk` = RSA 公钥加密(会话key的base64字符串)。
  static String buildBk() {
    if (_aesKeyBase64 == null) generateSessionKey();
    final pk = _publicKey();
    // 显式泛型：RSAEngine.init 需要 PublicKeyParameter<RSAPublicKey>
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(pk));
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
    // GCM-AEAD: content 末尾含16字节认证标签，整体作为一条AEAD输入解密
    final raw = base64.decode(contentB64);

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
    final out = Uint8List(gcm.getOutputSize(raw.length));
    var n = gcm.processBytes(raw, 0, raw.length, out, 0);
    // doFinal 返回值必须捕获：out 是 getOutputSize()(含16字节tag) 的整块缓冲，
    // 未写入的尾部是残留 NUL，直接整块 utf8.decode 会在尾部出现 \u0000 导致 JSON 解析失败。
    n += gcm.doFinal(out, n);
    return utf8.decode(Uint8List.sublistView(out, 0, n), allowMalformed: true);
  }

  /// AES-GCM 加密（请求侧）：key=会话key，iv 取 12字节随机，明文JSON → base64(ciphertext+16字节tag)。
  /// 与响应侧 aesGcmDecrypt 对称。调用方需自行生成并回传 bn(iv)，服务端用会话key+bn解密。
  /// ponytail: Question/* 等接口请求体加密进 `bp` 头，iv 放 `bn` 头。
  static String aesGcmEncrypt(String plaintext, Uint8List iv) {
    if (_aesKeyBase64 == null) {
      throw StateError('会话AES key未初始化，请先协商');
    }
    final keyBytes = base64.decode(_aesKeyBase64!);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(keyBytes),
          128,
          iv,
          Uint8List(0), // AAD空
        ),
      );
    final payload = utf8.encode(plaintext);
    final out = Uint8List(gcm.getOutputSize(payload.length));
    var n = gcm.processBytes(payload, 0, payload.length, out, 0);
    n += gcm.doFinal(out, n);
    // 尾部16字节是GCM tag，一并编码
    return base64.encode(Uint8List.sublistView(out, 0, n));
  }

  /// 生成12字节随机 iv（base64），用于请求侧加密。与响应 bn 同规格。
  static String generateIv() => base64.encode(_randomBytes(12));
}