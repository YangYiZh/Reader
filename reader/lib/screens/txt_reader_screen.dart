import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charset/charset.dart';
import 'package:reader/models/book.dart';
import 'package:reader/providers/reader_settings_provider.dart';
import 'package:reader/providers/bookshelf_provider.dart';

class TxtReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const TxtReaderScreen({super.key, required this.book});

  @override
  ConsumerState<TxtReaderScreen> createState() => _TxtReaderScreenState();
}

class _TxtReaderScreenState extends ConsumerState<TxtReaderScreen> {
  late String _content;
  int _currentPage = 0;
  List<String> _pages = [];
  bool _showControls = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadContent();
    _currentPage = widget.book.lastReadPosition;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _currentPage = (_scrollController.position.pixels / MediaQuery.of(context).size.height).floor();
      _saveProgress();
    });
  }

  Future<void> _loadContent() async {
    try {
      final file = File(widget.book.path);
      final bytes = await file.readAsBytes();
      
      // 检测文件编码
      final charset = await detectCharset(bytes);
      final encoding = charset ?? const Utf8Codec();
      
      // 读取文件内容
      _content = encoding.decode(bytes);
      
      // 分页
      _splitPages();
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取文件失败: $e')),
        );
      }
    }
  }

  void _splitPages() {
    if (_content.isEmpty) return;

    final settings = ref.read(readerSettingsProvider);
    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily,
      height: settings.lineHeight,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(text: 'A', style: textStyle),
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);

    final linesPerPage = (MediaQuery.of(context).size.height - 32) ~/ textPainter.height;
    final charsPerLine = _content.length ~/ (_content.split('\n').length);
    final charsPerPage = charsPerLine * linesPerPage;

    _pages = [];
    for (var i = 0; i < _content.length; i += charsPerPage) {
      final end = (i + charsPerPage < _content.length) ? i + charsPerPage : _content.length;
      _pages.add(_content.substring(i, end));
    }
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
    if (_pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _pages[_currentPage],
          style: TextStyle(
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
            color: settings.textColor,
            height: settings.lineHeight,
          ),
        ),
      ),
    );
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
                '${_currentPage + 1}/${_pages.length}页',
                style: const TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _saveProgress();
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentPage < _pages.length - 1
                        ? () {
                            setState(() {
                              _currentPage++;
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
                      _splitPages();
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
                      _splitPages();
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
                _splitPages();
                Navigator.pop(context);
              },
            );
          }).toList(),
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
      lastReadPosition: _currentPage,
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