import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/exam_provider.dart';

/// 单科成绩详情页
class ExamSubjectDetailPage extends StatefulWidget {
  final String examId;
  final String examName;
  final String subjectName;
  const ExamSubjectDetailPage({
    super.key,
    required this.examId,
    required this.examName,
    required this.subjectName,
  });

  @override
  State<ExamSubjectDetailPage> createState() => _ExamSubjectDetailPageState();
}

class _ExamSubjectDetailPageState extends State<ExamSubjectDetailPage> {
  List<Map<String, dynamic>>? _subjectList;
  Map<String, dynamic>? _currentSubject;

  @override
  void initState() {
    super.initState();
    _loadSubjectList();
  }

  Future<void> _loadSubjectList() async {
    final provider = context.read<ExamProvider>();
    final list = await provider.loadSubjectList(widget.examId);
    setState(() {
      _subjectList = list;
    });
  }

  void _onSubjectTap(Map<String, dynamic> subject) {
    setState(() {
      _currentSubject = subject;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.examName),
            Text(
              widget.subjectName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubjectList,
          ),
        ],
      ),
      body: _subjectList == null
          ? const Center(child: CircularProgressIndicator())
          : _subjectList!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_late, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无单科数据',
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 科目列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _subjectList!.length,
                        itemBuilder: (context, index) {
                          final subject = _subjectList![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  subject['subjectName']?.toString().substring(0, 1) ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              title: Text(subject['subjectName']?.toString() ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '得分: ${subject['score']?.toStringAsFixed(0) ?? '-'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (subject['fullScore'] != null)
                                    Text(
                                      '满分: ${subject['fullScore']?.toStringAsFixed(0) ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (subject['classRank'] != null)
                                    Text(
                                      '班级排名: ${subject['classRank']?.toStringAsFixed(0) ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (subject['gradeRank'] != null)
                                    Text(
                                      '年级排名: ${subject['gradeRank']?.toStringAsFixed(0) ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _onSubjectTap(subject),
                            ),
                          );
                        },
                      ),
                    ),
                    // 科目详情面板
                    if (_currentSubject != null) _SubjectDetailPanel(subject: _currentSubject!),
                  ],
                ),
    );
  }
}

/// 科目详情面板（底部抽屉）
class _SubjectDetailPanel extends StatelessWidget {
  final Map<String, dynamic> subject;

  const _SubjectDetailPanel({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 抽屉把手
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 科目名称
          Text(
            subject['subjectName']?.toString() ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 得分卡片
          _StatCard(
            label: '得分',
            value: '${subject['score']?.toStringAsFixed(0) ?? '-'}',
            subValue: '满分: ${subject['fullScore']?.toStringAsFixed(0) ?? '-'}',
          ),
          const SizedBox(height: 16),
          // 排名卡片
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '班级排名',
                  value: '${subject['classRank']?.toStringAsFixed(0) ?? '-'}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '年级排名',
                  value: '${subject['gradeRank']?.toStringAsFixed(0) ?? '-'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 平均分
          if (subject['classAvg'] != null || subject['gradeAvg'] != null)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: '班级平均',
                    value: '${subject['classAvg']?.toStringAsFixed(1) ?? '-'}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: '年级平均',
                    value: '${subject['gradeAvg']?.toStringAsFixed(1) ?? '-'}',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // 错题数
          if (subject['wrongCount'] != null)
            _StatCard(
              label: '错题数',
              value: '${subject['wrongCount']?.toStringAsFixed(0) ?? '-'}',
              valueColor: Colors.red,
            ),
        ],
      ),
    );
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.primaryColor,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}