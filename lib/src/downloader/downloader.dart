import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Fetches requests.
abstract interface class IDownloader<Req extends IRequest, Res extends IResponse> {
  set engine(Engine engine);

  /// Initializes downloader.
  Future<void> open();

  /// Performs fetch.
  Future<Res> fetch(Req request);

  /// Finalizes downloader.
  Future<void> close();
}

/// Middleware-based downloader.
class Downloader<Req extends IRequest, Res extends IResponse> implements IDownloader<Req, Res> {
  @override
  late final Engine engine;
  final List<DownloaderMiddleware<Req, Res>> middlewares;

  Downloader({this.middlewares = const []});

  @override
  Future<void> open() async {
    for (final m in middlewares) {
      await m.open();
    }
  }

  @override
  Future<Res> fetch(Req request) async {
    var req = request;
    for (final m in middlewares) {
      final res = await m.processRequest(req);
      if (res is ContinueChain<Req, Res>) {
        req = res.request;
      } else if (res is ForwardResponse<Req, Res>) {
        return res.response;
      } else if (res is ReportError<Req, Res>) {
        throw res.error;
      }
    }
    throw StateError('No middleware handled ${request.url}');
  }

  @override
  Future<void> close() async {
    for (final m in middlewares) {
      m.close();
    }
  }
}
