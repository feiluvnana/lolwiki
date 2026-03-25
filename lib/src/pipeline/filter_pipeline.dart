import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Drops items that don't pass [test].
class FilterPipeline<T> extends Pipeline<T> {
  final bool Function(T item) test;
  FilterPipeline(this.test);

  @override
  T? handle(T item) => test(item) ? item : null;
}
