import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Adds a delay before each request for polite crawling.
class DelayMiddleware<Req extends Request, Res extends Response>
    extends DownloaderMiddleware<Req, Res> {
  final Duration delay;
  const DelayMiddleware(this.delay);

  @override
  Future<DMResult<Req, Res>> processRequest(Req request) async {
    await Future.delayed(delay);
    return DMResult.continueWith(request);
  }
}
