import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import 'package:reader/models/book.dart';
import 'package:reader/providers/reader_settings_provider.dart';
import 'package:reader/providers/bookshelf_provider.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final EpubBook epubBook;

  const EpubReaderScreen({
    super.key,
    required this.book,
    required this.epubBook,
  });

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  late final List<EpubChapter> _chapters;
  int _currentChapterIndex = 0;
  double _scrollPosition = 0;
  bool _showControls = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chapters = widget.epubBook.Chapters;
    _currentChapterIndex = widget.book.lastReadPosition;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            _buildContent(settings),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ReaderSettings settings) {
    final chapter = _chapters[_currentChapterIndex];
    final htmlContent = chapter.HtmlContent;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.Title,
              style: TextStyle(
                fontSize: settings.fontSize * 1.2,
                fontFamily: settings.fontFamily,
                color: settings.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _cleanHtml(htmlContent),
              style: TextStyle(
                fontSize: settings.fontSize,
                fontFamily: settings.fontFamily,
                color: settings.textColor,
                height: settings.lineHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    // 简单的HTML清理，移除标签
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

  Widget _buildControls() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.black54,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _saveProgress();
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.book.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const Spacer(),
        Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsDialog(),
              ),
              Text(
                '${_currentChapterIndex + 1}/${_chapters.length}章',
                style: const TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentChapterIndex > 0
                        ? () {
                            setState(() {
                              _currentChapterIndex--;
                              _scrollPosition = 0;
                            });
                            _saveProgress();
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentChapterIndex < _chapters.length - 1
                        ? () {
                            setState(() {
                              _currentChapterIndex++;
                              _scrollPosition = 0;
                            });
                            _saveProgress();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    final settings = ref.read(readerSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('阅读设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('字体大小'),
              trailing: Text('${settings.fontSize.toInt()}'),
              onTap: () => _showFontSizeDialog(),
            ),
            ListTile(
              title: const Text('行间距'),
              trailing: Text('${settings.lineHeight}'),
              onTap: () => _showLineHeightDialog(),
            ),
            ListTile(
              title: const Text('字体'),
              trailing: Text(settings.fontFamily),
              onTap: () => _showFontFamilyDialog(),
            ),
            ListTile(
              title: const Text('背景颜色'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.backgroundColor,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: () => _showColorDialog(true),
            ),
            ListTile(
              title: const Text('文字颜色'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.textColor,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: () => _showColorDialog(false),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontFamilyDialog() {
    final settings = ref.read(readerSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择字体'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReaderSettingsNotifier.availableFonts.map((font) {
            return ListTile(
              title: Text(
                font,
                style: TextStyle(fontFamily: font),
              ),
              onTap: () {
                ref.read(readerSettingsProvider.notifier).updateSettings(
                      settings.copyWith(fontFamily: font),
                    );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    final settings = ref.read(readerSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体大小'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: settings.fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: settings.fontSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      ref.read(readerSettingsProvider.notifier).updateSettings(
                            settings.copyWith(fontSize: value),
                          );
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLineHeightDialog() {
    final settings = ref.read(readerSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('行间距'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: settings.lineHeight,
                  min: 1.0,
                  max: 2.0,
                  divisions: 10,
                  label: settings.lineHeight.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      ref.read(readerSettingsProvider.notifier).updateSettings(
                            settings.copyWith(lineHeight: value),
                          );
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showColorDialog(bool isBackground) {
    final settings = ref.read(readerSettingsProvider);
    final currentColor = isBackground ? settings.backgroundColor : settings.textColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBackground ? '背景颜色' : '文字颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              ref.read(readerSettingsProvider.notifier).updateSettings(
                    isBackground
                        ? settings.copyWith(backgroundColor: color)
                        : settings.copyWith(textColor: color),
                  );
            },
          ),
        ),
      ),
    );
  }

  void _saveProgress() {
    final updatedBook = widget.book.copyWith(
      lastReadPosition: _currentChapterIndex,
      lastReadTime: DateTime.now(),
    );
    ref.read(bookshelfProvider.notifier).updateBook(updatedBook);
  }
}

class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Colors.white,
        Colors.black,
        Colors.grey,
        Colors.brown,
        Colors.amber,
        Colors.orange,
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.blue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
      ].map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: pickerColor == color ? Colors.blue : Colors.grey,
                width: pickerColor == color ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
} 