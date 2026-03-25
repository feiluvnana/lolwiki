import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Logs items to console.
class LogPipeline<T> extends Pipeline<T> {
  final String prefix;
  LogPipeline([this.prefix = 'ITEM: ']);

  @override
  Future<T?> handle(T item) async {
    print('$prefix$item');
    return item;
  }
}
