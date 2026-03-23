import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Limits crawl depth by filtering [FollowResult]s that exceed [maxDepth].
///
/// Depth is tracked via `request.meta['depth']` (starts at 0).
class DepthMiddleware<T, Req extends Request, Res extends Response>
    extends ProcessorMiddleware<T, Req, Res> {
  final int maxDepth;
  const DepthMiddleware({this.maxDepth = 5});

  @override
  Stream<Result<T, Req>> onOutput(
    Res response,
    Stream<Result<T, Req>> results,
  ) async* {
    final currentDepth = (response.request.meta['depth'] as int?) ?? 0;
    await for (final result in results) {
      if (result is FollowResult<T, Req>) {
        final nextDepth = currentDepth + 1;
        if (nextDepth <= maxDepth) {
          yield Result.follow(
            result.request.copyWith(
              meta: {...result.request.meta, 'depth': nextDepth},
            ) as Req,
          );
        }
      } else {
        yield result;
      }
    }
  }
}
