import 'package:flncrawly/src/pipeline/pipeline.dart';

/// Logs each item to the console with a [prefix].
class LogPipeline<T> extends Pipeline<T> {
  final String prefix;
  LogPipeline([this.prefix = 'ITEM: ']);

  @override
  Future<T?> handle(T item) async {
    print('$prefix$item');
    return item;
  }
}
