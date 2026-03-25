import 'dart:convert';
import 'dart:io';

import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Collects and writes items to a JSON file.
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
