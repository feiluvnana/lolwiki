import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Sets a `User-Agent` if missing.
class UserAgentMiddleware<Req extends IRequest, Res extends IResponse> extends DownloaderMiddleware<Req, Res> {
  final String? fixedUserAgent;
  UserAgentMiddleware({this.fixedUserAgent});

  @override
  Future<DMResult<Req, Res>> processRequest(Req request) async {
    if (request.headers.containsKey('User-Agent')) {
      return DMResult.continueWith(request);
    }
    // Since copyWith isn't on IRequest, we check if it is a Request.
    if (request is Request) {
      final updatedHeaders = {...request.headers, 'User-Agent': 'flncrawly/1.0'};
      return DMResult.continueWith(request.copyWith(headers: updatedHeaders) as Req);
    }
    return DMResult.continueWith(request);
  }
}
