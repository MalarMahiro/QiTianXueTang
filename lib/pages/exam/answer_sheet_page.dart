import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../services/exam_service.dart';
import '../../services/logger.dart';

/// 答题卡/原卷查看页：黑底图库，横滑翻页 + 双指缩放 + 保存分享
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
  final PageController _pageController = PageController();
  bool _isLoading = true;
  bool _saving = false;
  String _error = '';
  String _status = '';
  final List<String> _imageUrls = [];
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    // 服务端返回 {answerUrls:[...], isWatermark}: 防御性收集所有 http 图片/PDF 地址
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
      _imageUrls.addAll(urls.where((u) => !u.toLowerCase().contains('.pdf')));
      if (_imageUrls.isEmpty && urls.isNotEmpty) {
        // 只有 PDF 等非图片资源
        _status = '共 ${urls.length} 个文件(非图片)';
      }
      if (_imageUrls.isEmpty) {
        _error = '暂无答题卡数据';
      }
    });
  }

  Future<void> _saveCurrent() async {
    if (_imageUrls.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final url = _imageUrls[_pageIndex];
      final resp = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/答题卡_${widget.km}_${_pageIndex + 1}.jpg');
      await file.writeAsBytes(resp.data!);
      await Share.shareXFiles([XFile(file.path)], text: '${widget.km} 答题卡');
    } catch (e) {
      logger.error('AnswerSheet', '保存失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.km} · 答题卡',
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveCurrent,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            tooltip: '保存',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && _imageUrls.isEmpty
              ? Center(
                  child: Text(_error,
                      style: const TextStyle(color: Colors.white70)))
              : Column(
                  children: [
                    Expanded(
                      child: PhotoViewGallery.builder(
                        pageController: _pageController,
                        itemCount: _imageUrls.length,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        builder: (context, i) => PhotoViewGalleryPageOptions(
                          imageProvider: NetworkImage(_imageUrls[i]),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 4,
                          initialScale: PhotoViewComputedScale.contained,
                          heroAttributes:
                              const PhotoViewHeroAttributes(tag: 'answer'),
                        ),
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.black),
                        loadingBuilder: (context, event) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    if (_status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_status,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _imageUrls.isEmpty
                              ? ''
                              : '第 ${_pageIndex + 1} 页（共 ${_imageUrls.length} 页）· 双指缩放',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
