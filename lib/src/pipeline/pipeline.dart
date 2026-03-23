import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';

/// Processes extracted items — validate, transform, store, or drop.
///
/// Return the item to pass it to the next pipeline, or `null` to drop it.
///
/// ```dart
/// class ValidatePipeline extends Pipeline<Book> {
///   @override
///   FutureOr<Book?> handle(Book item) {
///     if (item.title.isEmpty) return null; // drop invalid
///     return item;
///   }
/// }
/// ```
abstract class Pipeline<T> {
  late final Engine engine;

  FutureOr<T?> handle(T item);
  void close() {}
}
