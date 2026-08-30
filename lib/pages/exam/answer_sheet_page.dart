import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/exam_service.dart';
import '../../services/logger.dart';

/// 答题卡/原卷查看页
class AnswerSheetPage extends StatefulWidget {
  final String examId;
  final String examName;
  final String km;
  const AnswerSheetPage({
    super.key,
    required this.examId,
    required this.examName,
    required this.km,
  });

  @override
  State<AnswerSheetPage> createState() => _AnswerSheetPageState();
}

class _AnswerSheetPageState extends State<AnswerSheetPage> {
  final ExamService _examService = ExamService();
  bool _isLoading = true;
  String _error = '';
  final List<String> _imageUrls = [];
  final List<String> _pdfUrls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final resp = await _examService.getAnswerSheet(widget.examId, widget.km);
    if (!mounted) return;
    if (resp == null) {
      setState(() {
        _isLoading = false;
        _error = '获取答题卡失败';
      });
      return;
    }
    if (resp['error'] != null) {
      setState(() {
        _isLoading = false;
        _error = resp['error'].toString();
      });
      return;
    }

    // 服务端字段名未知, 防御性收集响应中所有 http 图片/PDF 地址
    final urls = <String>[];
    void walk(Object? node) {
      if (node is Map) {
        for (final v in node.values) {
          walk(v);
        }
      } else if (node is List) {
        for (final v in node) {
          walk(v);
        }
      } else if (node is String && node.startsWith('http')) {
        urls.add(node);
      }
    }
    walk(resp);
    logger.debug('AnswerSheet', '收集到 ${urls.length} 个链接: $urls');

    setState(() {
      _isLoading = false;
      _imageUrls.addAll(urls.where((u) =>
          u.toLowerCase().contains('.jpg') ||
          u.toLowerCase().contains('.jpeg') ||
          u.toLowerCase().contains('.png') ||
          u.toLowerCase().contains('.webp') ||
          !u.toLowerCase().contains('.pdf')));
      _pdfUrls.addAll(urls.where((u) => u.toLowerCase().contains('.pdf')));
      if (_imageUrls.isEmpty && _pdfUrls.isEmpty) {
        _error = '暂无答题卡数据';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.km} · 答题卡')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && _imageUrls.isEmpty && _pdfUrls.isEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: AppTheme.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final url in _imageUrls)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InteractiveViewer(
                          maxScale: 5,
                          child: Image.network(url, fit: BoxFit.fitWidth),
                        ),
                      ),
                    for (final url in _pdfUrls)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: const Text('原卷 PDF'),
                          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                  ],
                ),
    );
  }
}
