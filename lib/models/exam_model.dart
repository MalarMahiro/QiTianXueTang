class ExamModel {
  final String examId;
  final String examName;
  final String? subject;
  final String? gradeName;
  final String? examTime;
  final String? status;
  final double? totalScore;
  final double? studentScore;
  final double? classRank;
  final double? gradeRank;
  final double? classAvg;
  final double? gradeAvg;
  final List<SubjectScore>? subjects;

  ExamModel({
    required this.examId,
    required this.examName,
    this.subject,
    this.gradeName,
    this.examTime,
    this.status,
    this.totalScore,
    this.studentScore,
    this.classRank,
    this.gradeRank,
    this.classAvg,
    this.gradeAvg,
    this.subjects,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      examId: json['examId']?.toString() ?? '',
      examName: json['examName']?.toString() ?? '',
      subject: json['subject']?.toString(),
      gradeName: json['gradeName']?.toString(),
      examTime: json['examTime']?.toString(),
      status: json['status']?.toString(),
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      studentScore: (json['studentScore'] as num?)?.toDouble(),
      classRank: (json['classRank'] as num?)?.toDouble(),
      gradeRank: (json['gradeRank'] as num?)?.toDouble(),
      classAvg: (json['classAvg'] as num?)?.toDouble(),
      gradeAvg: (json['gradeAvg'] as num?)?.toDouble(),
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => SubjectScore.fromJson(e))
          .toList(),
    );
  }

  /// 考试列表解析：来自 getClaimExams 的 {examGuid,examName,type,time,score,aiState...}
  factory ExamModel.fromClaimJson(dynamic json) {
    final m = json is Map ? json : <String, dynamic>{};
    double? _d(Object? v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    return ExamModel(
      examId: m['examGuid']?.toString() ?? '',
      examName: m['examName']?.toString() ?? '',
      examTime: m['time']?.toString(),
      status: m['type']?.toString(),
      gradeName: m['grade']?.toString(),
      totalScore: _d(m['fullScore']) ?? _d(m['totalScore']),
      studentScore: _d(m['score']),
      // aiState/authView 用于详情是否可用
      subject: m['aiState']?.toString(),
    );
  }
}

class SubjectScore {
  final String subjectName;
  final double? score;
  final double? fullScore;
  final double? classAvg;
  final double? gradeAvg;
  final double? classRank;
  final double? gradeRank;

  SubjectScore({
    required this.subjectName,
    this.score,
    this.fullScore,
    this.classAvg,
    this.gradeAvg,
    this.classRank,
    this.gradeRank,
  });

  factory SubjectScore.fromJson(Map<String, dynamic> json) {
    return SubjectScore(
      subjectName: json['subjectName']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble(),
      fullScore: (json['fullScore'] as num?)?.toDouble(),
      classAvg: (json['classAvg'] as num?)?.toDouble(),
      gradeAvg: (json['gradeAvg'] as num?)?.toDouble(),
      classRank: (json['classRank'] as num?)?.toDouble(),
      gradeRank: (json['gradeRank'] as num?)?.toDouble(),
    );
  }
}