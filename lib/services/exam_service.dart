import '../../config/api.dart';
import '../../models/exam_model.dart';
import '../../models/study_report_model.dart';
import 'dio_client.dart';
import 'logger.dart';

class ExamService {
  final DioClient _client = DioClient();

  Future<List<ExamModel>> getExamList({int page = 1, int pageSize = 20}) async {
    try {
      logger.info('Exam', '获取考试列表: page=$page pageSize=$pageSize');
      final response = await _client.dio.get(
        ApiConfig.examList,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (response.data['code'] == 0 && response.data['data'] != null) {
        final list = response.data['data'] as List<dynamic>;
        final exams = list.map((e) => ExamModel.fromJson(e)).toList();
        logger.info('Exam', '获取考试列表成功: ${exams.length}条');
        return exams;
      }
      logger.warn('Exam', '获取考试列表失败: code=${response.data['code']}');
      return [];
    } catch (e) {
      logger.error('Exam', '获取考试列表异常', e);
      return [];
    }
  }

  Future<ExamModel?> getExamDetail(String examId) async {
    try {
      logger.info('Exam', '获取考试详情: examId=$examId');
      final response = await _client.dio.get(
        ApiConfig.examDetail,
        queryParameters: {'examId': examId},
      );
      if (response.data['code'] == 0) {
        return ExamModel.fromJson(response.data['data']);
      }
      logger.warn('Exam', '获取考试详情失败: code=${response.data['code']}');
      return null;
    } catch (e) {
      logger.error('Exam', '获取考试详情异常', e);
      return null;
    }
  }

  Future<StudyReportModel?> getStudyReport() async {
    try {
      logger.info('Exam', '获取学情报告');
      final response = await _client.dio.get(ApiConfig.studyReport);
      if (response.data['code'] == 0) {
        return StudyReportModel.fromJson(response.data['data']);
      }
      logger.warn('Exam', '获取学情报告失败: code=${response.data['code']}');
      return null;
    } catch (e) {
      logger.error('Exam', '获取学情报告异常', e);
      return null;
    }
  }
}