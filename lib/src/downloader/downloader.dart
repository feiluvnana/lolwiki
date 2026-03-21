import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The engine for downloading requests via a chain of middlewares.
class Downloader<T, Req extends Request, Res extends Response> {
  late final Engine<T, Req, Res> engine;
  final List<DownloaderMiddleware<Req, Res>> middlewares;

  Downloader({this.middlewares = const []});

  Future<DMResult<Req, Res>> handle(Req req) async {
    var curReq = req;
    for (var i = 0; i < middlewares.length; i++) {
      try {
        final res = await middlewares[i].processRequest(curReq);
        switch (res) {
          case NextRequest(:final request):
            curReq = request;
          case ProxyResponse(:final response):
            return _handleRes(curReq, response, i);
          case RescheduleRequest() || ReportError() || IgnoreResult():
            return res;
        }
      } catch (e) {
        return _handleErr(curReq, e, i);
      }
    }
    return DMResult.error(StateError('No fetcher handled ${curReq.url}'));
  }

  Future<DMResult<Req, Res>> _handleRes(Req r, Res res, int si) async {
    var curRes = res;
    for (var i = si; i >= 0; i--) {
      try {
        final reslt = await middlewares[i].processResponse(r, curRes);
        switch (reslt) {
          case ProxyResponse(:final response):
            curRes = response;
          case RescheduleRequest() || ReportError() || IgnoreResult():
            return reslt;
          case NextRequest():
            throw StateError('Downloader: Invalid response yield');
        }
      } catch (e) {
        return _handleErr(r, e, i - 1);
      }
    }
    return DMResult.response(curRes);
  }

  Future<DMResult<Req, Res>> _handleErr(Req r, Object e, int si) async {
    var curErr = e;
    for (var i = si; i >= 0; i--) {
      try {
        final reslt = await middlewares[i].processException(r, curErr);
        switch (reslt) {
          case ReportError(:final error):
            curErr = error;
          case ProxyResponse(:final response):
            return _handleRes(r, response, i - 1);
          case RescheduleRequest() || IgnoreResult():
            return reslt;
          case NextRequest():
            throw StateError('Downloader: Invalid error yield');
        }
      } catch (e) {
        curErr = e;
      }
    }
    return DMResult.error(curErr);
  }

  void close() {
    for (var m in middlewares) {
      m.close();
    }
  }
}
