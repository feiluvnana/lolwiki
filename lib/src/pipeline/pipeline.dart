import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';

/// Processes extracted items.
abstract class Pipeline<T> {
  late final Engine engine;

  FutureOr<T?> handle(T item);
  void close() {}
}
