import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:reader/models/book.dart';
import 'package:reader/providers/bookshelf_provider.dart';
import 'package:reader/screens/reader_screen.dart';
import 'package:reader/utils/book_utils.dart';
import 'package:reader/theme/app_theme.dart';

class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  final _dio = Dio();
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt'],
      );

      if (result != null) {
        final file = result.files.first;
        final coverPath = await BookUtils.extractCover(file.path!);
        
        final book = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: file.name,
          path: file.path!,
          coverPath: coverPath,
          lastReadPosition: 0,
          lastReadTime: DateTime.now(),
        );

        ref.read(bookshelfProvider.notifier).addBook(book);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入文件失败: $e')),
        );
      }
    }
  }

  Future<void> _importFromUrl() async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从网络导入'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: '请输入文件URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        setState(() {
          _isDownloading = true;
          _downloadProgress = 0;
        });

        final tempDir = await getTemporaryDirectory();
        final fileName = result.split('/').last;
        final filePath = '${tempDir.path}/$fileName';

        await _dio.download(
          result,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );

        final coverPath = await BookUtils.extractCover(filePath);
        
        final book = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName,
          path: filePath,
          coverPath: coverPath,
          lastReadPosition: 0,
          lastReadTime: DateTime.now(),
        );

        ref.read(bookshelfProvider.notifier).addBook(book);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载文件失败: $e')),
          );
        }
      } finally {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookshelfProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Text('导入本地图书'),
              ),
              const PopupMenuItem(
                value: 'import_url',
                child: Text('从网络导入'),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: Text('排序方式'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importBook();
                  break;
                case 'import_url':
                  _importFromUrl();
                  break;
                case 'sort':
                  // TODO: 实现排序功能
                  break;
              }
            },
          ),
        ],
      ),
      body: _isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 5.0,
                    percent: _downloadProgress,
                    center: Text('${(_downloadProgress * 100).toInt()}%'),
                    progressColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('正在下载...'),
                ],
              ),
            )
          : books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '书架空空如也',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角添加书籍',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReaderScreen(book: book),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: book.coverPath != null
                                    ? Image.file(
                                        File(book.coverPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: theme.colorScheme.surface,
                                        child: Icon(
                                          Icons.book,
                                          size: 48,
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.5),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '上次阅读: ${book.lastReadTime.toString().split(' ')[0]}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 