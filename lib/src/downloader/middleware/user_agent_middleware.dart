import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/request/user_agents.dart';
import 'package:flncrawly/src/response/response.dart';

/// Sets a `User-Agent` header on requests that don't already have one.
class UserAgentMiddleware<Req extends Request, Res extends Response>
    extends DownloaderMiddleware<Req, Res> {
  final String? fixedUserAgent;
  UserAgentMiddleware({this.fixedUserAgent});

  @override
  Future<DMResult<Req, Res>> processRequest(Req request) async {
    if (request.headers.containsKey('User-Agent')) {
      return DMResult.continueWith(request);
    }
    final userAgent = fixedUserAgent ?? UserAgents.random();
    final updatedHeaders = {...request.headers, 'User-Agent': userAgent};
    return DMResult.continueWith(request.copyWith(headers: updatedHeaders) as Req);
  }
}
