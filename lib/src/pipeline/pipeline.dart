import 'dart:async';
import 'package:flncrawly/src/core/engine.dart';

/// Base for item processing.
abstract class Pipeline<T> {
  late final Engine engine;
  Future<void> open() async {}
  FutureOr<T?> handle(T item);
  void close() {}
}
