import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import 'package:pdfx/pdfx.dart';
import 'package:reader/models/book.dart';
import 'package:reader/providers/reader_settings_provider.dart';
import 'package:reader/providers/bookshelf_provider.dart';
import 'package:reader/screens/epub_reader_screen.dart';
import 'package:reader/screens/txt_reader_screen.dart';
import 'package:reader/theme/app_theme.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late bool _isPdf;
  late bool _isTxt;
  PdfController? _pdfController;
  EpubBook? _epubBook;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _isPdf = widget.book.path.toLowerCase().endsWith('.pdf');
    _isTxt = widget.book.path.toLowerCase().endsWith('.txt');
    
    if (_isPdf) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.book.path),
        initialPage: widget.book.lastReadPosition,
      );
    } else if (!_isTxt) {
      _loadEpub();
    }
  }

  Future<void> _loadEpub() async {
    try {
      _epubBook = await EpubReader.readBook(widget.book.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取EPUB文件失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isPdf) {
      return _buildPdfViewer(theme);
    } else if (_isTxt) {
      return TxtReaderScreen(book: widget.book);
    } else if (_epubBook != null) {
      return EpubReaderScreen(book: widget.book, epubBook: _epubBook!);
    } else {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }

  Widget _buildPdfViewer(ThemeData theme) {
    return Scaffold(
      body: Stack(
        children: [
          PdfView(
            controller: _pdfController!,
            onPageChanged: (page) {
              final updatedBook = widget.book.copyWith(
                lastReadPosition: page,
                lastReadTime: DateTime.now(),
              );
              ref.read(bookshelfProvider.notifier).updateBook(updatedBook);
            },
          ),
          if (_showControls) _buildControls(theme),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.book.title,
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: 实现更多设置
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  _pdfController?.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              Text(
                '${_pdfController?.page ?? 0}/${_pdfController?.pagesCount ?? 0}',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  _pdfController?.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
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