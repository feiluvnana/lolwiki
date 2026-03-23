import 'dart:convert';
import 'dart:io';

import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Collects all items and writes them to a JSON file on close.
///
/// If [T] is a `Map` or `List`, it serializes directly. Otherwise,
/// provide a [toJson] converter function.
///
/// ```dart
/// // Maps serialize directly
/// Crawly(MyProcessor())
///     .pipe(JsonFilePipeline('output.json'))
///     .crawl();
///
/// // Custom objects need a converter
/// Crawly(BookProcessor())
///     .pipe(JsonFilePipeline('books.json', toJson: (b) => {
///       'title': b.title,
///       'price': b.price,
///     }))
///     .crawl();
/// ```
class JsonFilePipeline<T> extends Pipeline<T> {
  final String path;
  final dynamic Function(T)? toJson;
  final List<dynamic> _buffer = [];

  JsonFilePipeline(this.path, {this.toJson});

  @override
  T? handle(T item) {
    _buffer.add(toJson != null ? toJson!(item) : item);
    return item;
  }

  @override
  void close() {
    final json = const JsonEncoder.withIndent('  ').convert(_buffer);
    File(path).writeAsStringSync(json);
  }
}
