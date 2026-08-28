# 七天学堂 - Flutter 重构版

> 原 App 为 Cordova + Ionic 混合壳，经逆向分析后使用 Flutter 3.47 完整重写。
> 基于真实 HAR 抓包（332 个请求）还原接口，精简 30+ 广告 SDK，仅保留核心业务功能。

## 项目结构

```
lib/
├── main.dart                 # 入口 + MultiProvider 配置
├── config/
│   ├── api.dart              # API 端点配置（按业务拆分子域名）
│   └── theme.dart            # 主题（主色 #ED5B68）
├── models/
│   ├── user_model.dart       # 用户模型（含防御性多键映射）
│   ├── exam_model.dart       # 考试/成绩模型（列表+详情双工厂）
│   └── study_report_model.dart # 学情报告模型（预留）
├── services/
│   ├── dio_client.dart       # HTTP 客户端（单例 + 拦截器 + AES解密）
│   ├── auth_service.dart     # 登录/会话管理
│   ├── exam_service.dart     # 成绩数据接口
│   ├── home_service.dart     # 首页数据（导航/板块/广告/学情/消息）
│   ├── secure_crypto.dart    # 会话 AES-GCM 加密（请求+响应）
│   ├── qitian_crypto.dart    # 固定 AES-ECB 解密 + 密码加密
│   └── logger.dart           # 日志工具
├── providers/
│   ├── auth_provider.dart    # 认证状态管理
│   ├── exam_provider.dart    # 考试数据状态管理
│   └── home_provider.dart    # 首页数据状态管理
├── pages/
│   ├── splash_page.dart      # 启动页
│   ├── login_page.dart       # 登录页
│   ├── home_page.dart        # 首页 + 底部导航
│   ├── exam/
│   │   ├── exam_list_page.dart  # 考试列表
│   │   └── exam_detail_page.dart # 考试详情
│   ├── course/
│   │   └── course_list_page.dart # 课程列表
│   └── profile/
│       └── profile_page.dart # 个人中心（昵称编辑）
└── widgets/                  # 公共组件（预留）
```

## 技术栈

- **Flutter** 3.47.1 · Dart 3.13.1
- **状态管理**：Provider
- **网络**：Dio（拦截器 → Token 自动注入 + AES 响应解密）
- **加密**：pointycastle（AES-256-ECB / AES-256-GCM）
- **存储**：SharedPreferences + flutter_secure_storage
- **其他**：WebView、图片选择、扫码、视频播放、url_launcher

## 加密机制

整个 App 的 API 通信有三种加密模式，均从原 APK 逆向还原：

### 1. 固定 AES-256-ECB（响应侧）
- 考试列表 `getClaimExams`、`getExamCount` 等接口
- 响应体 `data.isEncrypt=true`，`content` 用固定 key 做 AES-256-ECB/Pkcs7 解密
- key = UTF-8("c0f1a30cba2147949ee71cf71cba3c20")，32 字节
- 见 `QitianCrypto.aesEcbDecryptBase64()`

### 2. 会话 AES-256-GCM（响应侧）
- `GetUserInfo`、`Question/*` 等接口
- 响应体 `data.isEncrypt=true` + `bn`(iv) + `content`(密文+16字节GCM tag)
- key 由 App 随机生成（32字节），RSA 公钥加密后通过 `bk` 头协商
- 见 `SecureCrypto.aesGcmDecrypt()`

### 3. 会话 AES-256-GCM（请求侧）
- `Question/*` 等 POST 接口，请求体加密进 `bp` 头
- iv 在 `bn` 头，密文在 `bp` 头，用同一会话 key 加密
- 见 `SecureCrypto.aesGcmEncrypt()`

### 密码加密
- `base64(明文密码 + 常量后缀 "{MTgyMjU2MDU0MjF7c3pvbmV9}")`
- 见 `QitianCrypto.encryptPassword()`

### 认证方式
- 登录获取 `Token`，后续请求放在 `Token` 头（非 Bearer）
- 同时固定 `Version: 4.6.1` 头
- 会话密钥协商：`POST /user` 空 body + `bk` 头

## 快速开始

### 环境要求

- Flutter 3.47+
- Android SDK 35+
- JDK 17+

### 构建

```bash
# 获取依赖
flutter pub get

# 创建 local.properties（填入你的 SDK 路径）
echo "flutter.sdk=/path/to/flutter" > android/local.properties
echo "sdk.dir=/path/to/android-sdk" >> android/local.properties

# 调试构建
flutter build apk --debug

# 发布构建（需配置签名）
flutter build apk --release
```

### API 配置

API 按业务拆分子域名，均可在 `lib/config/api.dart` 中修改：

| 域名 | 用途 |
|------|------|
| `szone-my.7net.cc` | 用户认证、学情、消息 |
| `szone-score.7net.cc` | 成绩查询 |
| `szone-index.7net.cc` | 首页导航、广告 |
| `szone-homework.7net.cc` | 作业（预留） |

## 已实现功能

- [x] 手机号密码登录（含会话密钥协商）
- [x] 首页宫格导航 + 板块图 + 广告
- [x] 学情数据（累计学时/收藏数）
- [x] 消息未读角标
- [x] 考试列表（含未认领考试数）
- [x] 考试详情（请求侧 GCM 加密，需真机确认入参）
- [x] 编辑昵称
- [x] 底部 4Tab 导航（首页/考试/课程/我的）

## 项目特点

| 维度 | 原 App | 重构版 |
|------|--------|--------|
| 架构 | Cordova + Ionic/Angular | Flutter 原生 |
| 广告 SDK | 30+（穿山甲/优量汇/百度/华为等） | 0 |
| APK 大小 | ~85MB | ~15MB（预估） |
| 权限数 | 40+ | 5 |
| 性能 | WebView 混合渲染 | 原生 GPU 渲染 |
| 抓包还原 | - | 基于 332 条真实 HAR 请求 |

## 逆向说明

本项目基于对原 App 的 HAR 抓包分析和 APK 逆向：

1. **HAR 抓包**：Reqable 抓取 332 个请求，覆盖全部业务接口
2. **AES key 提取**：从原 App JS 源码中提取固定 AES-256-ECB key
3. **RSA 公钥提取**：从 APK 中提取服务器 RSA 公钥（DER/X509）
4. **会话密钥还原**：复现 RSA 加密 → POST 协商 → GCM 解密完整链路
5. **字段映射**：通过 `common/upload` 上报 body 验证 GetUserInfo 解密的真实字段名

## 许可

本代码仅供学习参考，请勿用于商业用途。