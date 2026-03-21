import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// A middleware that tracks and limits the depth of a crawl.
/// Depth is stored in `request.meta['depth']`.
class DepthMiddleware<T, Req extends Request, Res extends Response>
    extends ProcessorMiddleware<T, Req, Res> {
  final int maxDepth;

  const DepthMiddleware({this.maxDepth = 5});

  @override
  Stream<PMResult<T, Req>> onOutput(
    Res res,
    Stream<PMResult<T, Req>> results,
  ) async* {
    final currentDepth = (res.request.meta['depth'] as int?) ?? 0;

    await for (final r in results) {
      if (r is Follow<T, Req>) {
        final nextDepth = currentDepth + 1;
        if (nextDepth <= maxDepth) {
          yield PMResult.follow(
            r.request.copyWith(meta: {...r.request.meta, 'depth': nextDepth})
                as Req,
          );
        }
      } else {
        yield r;
      }
    }
  }
}
