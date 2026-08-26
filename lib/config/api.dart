/// 七天学堂 API 配置
/// Ponytail: 从原Cordova App反编译提取的API端点
class ApiConfig {
  static const String baseUrl = 'https://api.7net.cc';
  static const String h5Base = 'https://h5.7net.cc';

  // 用户相关
  static const String login = '/api/v1/user/login';
  static const String smsCode = '/api/v1/user/sms/code';
  static const String userInfo = '/api/v1/user/info';
  static const String refreshToken = '/api/v1/user/token/refresh';

  // 成绩相关
  static const String examList = '/api/v1/exam/list';
  static const String examDetail = '/api/v1/exam/detail';
  static const String examScore = '/api/v1/exam/score';
  static const String examAnalysis = '/api/v1/exam/analysis';
  static const String subjectScore = '/api/v1/exam/subject/score';

  // 学情
  static const String studyReport = '/api/v1/study/report';
  static const String studyTrend = '/api/v1/study/trend';

  // 课程
  static const String courseList = '/api/v1/course/list';
  static const String courseDetail = '/api/v1/course/detail';
  static const String videoList = '/api/v1/video/list';

  // AI
  static const String aiAnalysis = '/api/v1/ai/analysis';
  static const String aiChat = '/api/v1/ai/chat';

  // 选科/志愿
  static const String subjectSelection = '/api/v1/subject/selection';
  static const String volunteerRecommend = '/api/v1/volunteer/recommend';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}