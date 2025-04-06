import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class BookUtils {
  static Future<String?> extractCover(String bookPath) async {
    if (bookPath.toLowerCase().endsWith('.pdf')) {
      return _extractPdfCover(bookPath);
    } else if (bookPath.toLowerCase().endsWith('.epub')) {
      return _extractEpubCover(bookPath);
    }
    return null;
  }

  static Future<String?> _extractPdfCover(String pdfPath) async {
    try {
      final document = await PdfDocument.openFile(pdfPath);
      final page = await document.getPage(1);
      final image = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      final tempDir = await getTemporaryDirectory();
      final coverPath = '${tempDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(coverPath);
      await file.writeAsBytes(image!.bytes);

      return coverPath;
    } catch (e) {
      print('提取PDF封面失败: $e');
      return null;
    }
  }

  static Future<String?> _extractEpubCover(String epubPath) async {
    try {
      final book = await EpubReader.readBook(File(epubPath));
      final coverImage = book.CoverImage;
      
      if (coverImage == null) {
        // 如果没有封面，尝试从第一个图片章节中提取
        for (final chapter in book.Chapters) {
          if (chapter.HtmlContent.contains('<img')) {
            final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(chapter.HtmlContent);
            if (imgMatch != null) {
              final imgPath = imgMatch.group(1);
              if (imgPath != null) {
                final imgFile = book.Content.Images[imgPath];
                if (imgFile != null) {
                  final tempDir = await getTemporaryDirectory();
                  final coverPath = '${tempDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final file = File(coverPath);
                  await file.writeAsBytes(imgFile.Content);
                  return coverPath;
                }
              }
            }
          }
        }
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final coverPath = '${tempDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(coverPath);
      await file.writeAsBytes(coverImage.Content);
      return coverPath;
    } catch (e) {
      print('提取EPUB封面失败: $e');
      return null;
    }
  }
} 