import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Auto-retries requests that receive server error responses.
class RetryMiddleware<Req extends Request, Res extends Response> extends DownloaderMiddleware<Req, Res> {
  final int maxRetries;
  final Set<int> retryOnStatusCodes;

  const RetryMiddleware({this.maxRetries = 3, this.retryOnStatusCodes = const {500, 502, 503, 504, 408, 429}});

  @override
  Future<DMResult<Req, Res>> processResponse(Req request, Res response) async {
    final retries = (request.meta['retries'] as int?) ?? 0;
    if (retryOnStatusCodes.contains(response.status) && retries < maxRetries) {
      return DMResult.reschedule(request.copyWith(meta: {
        ...request.meta,
        'retries': retries + 1,
        'dontFilter': true,
      }) as Req);
    }
    return DMResult.respond(response);
  }
}
