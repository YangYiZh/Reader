import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:reader/models/book.dart';

final bookshelfProvider = StateNotifierProvider<BookshelfNotifier, List<Book>>((ref) {
  return BookshelfNotifier();
});

class BookshelfNotifier extends StateNotifier<List<Book>> {
  BookshelfNotifier() : super([]) {
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final box = await Hive.openBox<Book>('books');
    state = box.values.toList();
  }

  Future<void> addBook(Book book) async {
    final box = await Hive.openBox<Book>('books');
    await box.put(book.id, book);
    state = [...state, book];
  }

  Future<void> removeBook(String id) async {
    final box = await Hive.openBox<Book>('books');
    await box.delete(id);
    state = state.where((book) => book.id != id).toList();
  }

  Future<void> updateBook(Book book) async {
    final box = await Hive.openBox<Book>('books');
    await box.put(book.id, book);
    state = state.map((b) => b.id == book.id ? book : b).toList();
  }
} 