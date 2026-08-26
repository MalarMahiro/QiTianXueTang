# 七天学堂 - Flutter 重构版

> 原 App 为 Cordova + Ionic 混合壳，经逆向分析后使用 Flutter 3.47 完整重写。
> 精简了 30+ 广告 SDK，仅保留核心业务功能：成绩查询、学情分析、课程视频。

## 项目结构

```
lib/
├── main.dart                 # 入口 + Provider 配置
├── config/
│   ├── api.dart              # API 端点配置
│   └── theme.dart            # 主题（主色 #ED5B68）
├── models/
│   ├── user_model.dart       # 用户模型
│   ├── exam_model.dart       # 考试/成绩模型
│   └── study_report_model.dart # 学情报告模型
├── services/
│   ├── dio_client.dart       # HTTP 客户端（单例 + 拦截器）
│   ├── auth_service.dart     # 登录/Token 管理
│   └── exam_service.dart     # 成绩数据接口
├── providers/
│   ├── auth_provider.dart    # 认证状态管理
│   └── exam_provider.dart    # 考试数据状态管理
├── pages/
│   ├── splash_page.dart      # 启动页
│   ├── login_page.dart       # 登录页
│   ├── home_page.dart        # 首页 + 底部导航
│   ├── exam_list_page.dart   # 考试列表
│   ├── exam_detail_page.dart # 考试详情
│   ├── course_list_page.dart # 课程列表
│   └── profile_page.dart     # 个人中心
└── widgets/                  # 公共组件
```

## 技术栈

- **Flutter** 3.47.1 · Dart 3.13.1
- **状态管理**：Provider
- **路由**：GoRouter
- **网络**：Dio（拦截器 → Token 自动刷新）
- **图表**：fl_chart
- **存储**：SharedPreferences + flutter_secure_storage
- **其他**：WebView、扫码、图片选择、视频播放、权限管理

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

API 基地址为 `https://api.7net.cc`，可在 `lib/config/api.dart` 中修改。

## 与原 App 对比

| 维度 | 原 App | 重构版 |
|------|--------|--------|
| 架构 | Cordova + Ionic/Angular | Flutter 原生 |
| 广告 SDK | 30+（穿山甲/优量汇/百度/华为等） | 0 |
| APK 大小 | ~85MB | ~15MB（预估） |
| 权限数 | 40+ | 5 |
| 性能 | WebView 混合渲染 | 原生 GPU 渲染 |

## 功能

- [x] 手机号/短信验证码登录
- [x] 考试成绩列表与详情
- [x] 各科分数分布图表
- [x] 历史成绩趋势
- [x] 学情分析报告
- [x] 课程视频列表
- [x] AI 智能分析
- [x] 选科/志愿推荐

## 许可

本代码仅供学习参考，请勿用于商业用途。