import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String? coverPath;

  @HiveField(4)
  final int lastReadPosition;

  @HiveField(5)
  final DateTime lastReadTime;

  Book({
    required this.id,
    required this.title,
    required this.path,
    this.coverPath,
    required this.lastReadPosition,
    required this.lastReadTime,
  });

  Book copyWith({
    String? id,
    String? title,
    String? path,
    String? coverPath,
    int? lastReadPosition,
    DateTime? lastReadTime,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      coverPath: coverPath ?? this.coverPath,
      lastReadPosition: lastReadPosition ?? this.lastReadPosition,
      lastReadTime: lastReadTime ?? this.lastReadTime,
    );
  }
} 