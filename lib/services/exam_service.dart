import 'package:dio/dio.dart';
import '../../config/api.dart';
import '../../models/exam_model.dart';
import '../../models/study_report_model.dart';
import 'dio_client.dart';

class ExamService {
  final DioClient _client = DioClient();

  Future<List<ExamModel>> getExamList({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _client.dio.get(
        ApiConfig.examList,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (response.data['code'] == 0 && response.data['data'] != null) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((e) => ExamModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ExamModel?> getExamDetail(String examId) async {
    try {
      final response = await _client.dio.get(
        ApiConfig.examDetail,
        queryParameters: {'examId': examId},
      );
      if (response.data['code'] == 0) {
        return ExamModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StudyReportModel?> getStudyReport() async {
    try {
      final response = await _client.dio.get(ApiConfig.studyReport);
      if (response.data['code'] == 0) {
        return StudyReportModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}