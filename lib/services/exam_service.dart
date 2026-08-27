import '../../models/exam_model.dart';
import '../../models/study_report_model.dart';

class ExamService {
  /// 获取考试列表。ponytail: 真实端点尚未抓包，先返回空列表占位。
  Future<List<ExamModel>> getExamList({int page = 1, int pageSize = 20}) async {
    return [];
  }

  Future<ExamModel?> getExamDetail(String examId) async {
    return null;
  }

  Future<StudyReportModel?> getStudyReport() async {
    return null;
  }
}