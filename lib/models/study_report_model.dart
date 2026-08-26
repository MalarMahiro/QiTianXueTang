class StudyReportModel {
  final String? title;
  final String? summary;
  final double? studyHours;
  final double? completionRate;
  final List<WeakSubject>? weakSubjects;
  final List<TrendPoint>? trend;

  StudyReportModel({
    this.title,
    this.summary,
    this.studyHours,
    this.completionRate,
    this.weakSubjects,
    this.trend,
  });

  factory StudyReportModel.fromJson(Map<String, dynamic> json) {
    return StudyReportModel(
      title: json['title']?.toString(),
      summary: json['summary']?.toString(),
      studyHours: (json['studyHours'] as num?)?.toDouble(),
      completionRate: (json['completionRate'] as num?)?.toDouble(),
      weakSubjects: (json['weakSubjects'] as List<dynamic>?)
          ?.map((e) => WeakSubject.fromJson(e))
          .toList(),
      trend: (json['trend'] as List<dynamic>?)
          ?.map((e) => TrendPoint.fromJson(e))
          .toList(),
    );
  }
}

class WeakSubject {
  final String subjectName;
  final double? score;
  final double? fullScore;
  final String? suggestion;

  WeakSubject({
    required this.subjectName,
    this.score,
    this.fullScore,
    this.suggestion,
  });

  factory WeakSubject.fromJson(Map<String, dynamic> json) {
    return WeakSubject(
      subjectName: json['subjectName']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble(),
      fullScore: (json['fullScore'] as num?)?.toDouble(),
      suggestion: json['suggestion']?.toString(),
    );
  }
}

class TrendPoint {
  final String? date;
  final double? score;
  final double? avgScore;

  TrendPoint({this.date, this.score, this.avgScore});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date']?.toString(),
      score: (json['score'] as num?)?.toDouble(),
      avgScore: (json['avgScore'] as num?)?.toDouble(),
    );
  }
}