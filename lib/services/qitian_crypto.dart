import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../config/api.dart';

/// 七天学堂加解密工具
/// Ponytail: 从原App前端JS逆向。
/// - 响应当 data.isEncrypt==true 时，content 字段用 AES-256-ECB/Pkcs7 解密，
///   key = utf8(aesKey字符串) 即32字节。
///   原JS: `h = enc.Utf8.parse("c0f1a30cba...")`, `AES.decrypt(content, h, {mode:ECB,padding:Pkcs7})`
/// - 登录密码: password = b64( 明文密码 + 常量后缀 "{MTgyMjU2MDU0MjF7c3pvbmV9}" )
///   原模块 e/ey: `t => t ? btoa(t + [...]reverse().join("")) : t`
class QitianCrypto {
  QitianCrypto._();

  /// AES-256-ECB 解密(base64输入), key = utf8(aesKey) 即32字节
  static String aesEcbDecryptBase64(String base64Cipher, {String? key}) {
    final keyBytes = Uint8List.fromList(
        utf8.encode(key ?? ApiConfig.aesKey)); // 32 bytes
    final cipherBytes = base64.decode(base64Cipher);

    final aes = ECBBlockCipher(AESEngine())..init(false, KeyParameter(keyBytes));

    final blockSize = 16;
    final out = Uint8List(cipherBytes.length);
    for (var i = 0; i < cipherBytes.length; i += blockSize) {
      aes.processBlock(cipherBytes, i, out, i);
    }
    return utf8.decode(_pkcs7Unpad(out), allowMalformed: true);
  }

  /// 登录密码加密：password = base64(明文密码 + 常量后缀)
  /// 后缀是固定常量，与用户名/手机号无关。
  static String encryptPassword(String plainPassword) {
    const suffix = '{MTgyMjU2MDU0MjF7c3pvbmV9}';
    return base64.encode(utf8.encode('$plainPassword$suffix'));
  }

  static Uint8List _pkcs7Unpad(Uint8List data) {
    if (data.isEmpty) return data;
    final pad = data[data.length - 1];
    if (pad < 1 || pad > 16) return data;
    return Uint8List.sublistView(data, 0, data.length - pad);
  }
}