import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Functional one-off pipeline.
class FunctionalPipeline<T> extends Pipeline<T> {
  final Future<T?> Function(T item) _handler;
  final void Function()? _onClose;

  FunctionalPipeline(this._handler, [this._onClose]);

  @override
  Future<T?> handle(T item) => _handler(item);

  @override
  void close() => _onClose?.call();
}
