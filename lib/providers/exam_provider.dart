import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';
import '../models/study_report_model.dart';
import '../services/exam_service.dart';

class ExamProvider extends ChangeNotifier {
  final ExamService _examService = ExamService();
  List<ExamModel> _exams = [];
  ExamModel? _currentExam;
  StudyReportModel? _studyReport;
  bool _isLoading = false;

  List<ExamModel> get exams => _exams;
  ExamModel? get currentExam => _currentExam;
  StudyReportModel? get studyReport => _studyReport;
  bool get isLoading => _isLoading;

  Future<void> loadExams() async {
    _isLoading = true;
    // 延后一次事件循环，避免在 initState build 期间同步 notifyListeners
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
    _exams = await _examService.getExamList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExamDetail(String examId) async {
    _isLoading = true;
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
    _currentExam = await _examService.getExamDetail(examId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStudyReport() async {
    _isLoading = true;
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
    _studyReport = await _examService.getStudyReport();
    _isLoading = false;
    notifyListeners();
  }
}