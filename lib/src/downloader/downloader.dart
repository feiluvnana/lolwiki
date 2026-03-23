import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Runs requests through a chain of [DownloaderMiddleware]s.
///
/// ```
/// Request → [MW₁.processRequest] → [MW₂.processRequest] → ... → Network
///                                                                    ↓
/// Engine ← [MW₁.processResponse] ← [MW₂.processResponse] ← ... ← Response
/// ```
class Downloader<T, Req extends Request, Res extends Response> {
  late final Engine<T, Req, Res> engine;
  final List<DownloaderMiddleware<Req, Res>> middlewares;

  Downloader({this.middlewares = const []});

  Future<DMResult<Req, Res>> fetch(Req request) async {
    var currentRequest = request;
    for (var i = 0; i < middlewares.length; i++) {
      try {
        final result = await middlewares[i].processRequest(currentRequest);
        switch (result) {
          case ContinueChain(:final request):
            currentRequest = request;
          case ForwardResponse(:final response):
            return _processResponseChain(currentRequest, response, i);
          case RescheduleRequest() || ReportError() || DropRequest():
            return result;
        }
      } catch (e) {
        return _processExceptionChain(currentRequest, e, i);
      }
    }
    return DMResult.fail(StateError('No middleware fetched ${currentRequest.url}'));
  }

  Future<DMResult<Req, Res>> _processResponseChain(
    Req request, Res response, int fromIndex,
  ) async {
    var currentResponse = response;
    for (var i = fromIndex; i >= 0; i--) {
      try {
        final result = await middlewares[i].processResponse(request, currentResponse);
        switch (result) {
          case ForwardResponse(:final response):
            currentResponse = response;
          case RescheduleRequest() || ReportError() || DropRequest():
            return result;
          case ContinueChain():
            throw StateError('processResponse cannot return continueWith');
        }
      } catch (e) {
        return _processExceptionChain(request, e, i - 1);
      }
    }
    return DMResult.respond(currentResponse);
  }

  Future<DMResult<Req, Res>> _processExceptionChain(
    Req request, Object error, int fromIndex,
  ) async {
    var currentError = error;
    for (var i = fromIndex; i >= 0; i--) {
      try {
        final result = await middlewares[i].processException(request, currentError);
        switch (result) {
          case ReportError(:final error):
            currentError = error;
          case ForwardResponse(:final response):
            return _processResponseChain(request, response, i - 1);
          case RescheduleRequest() || DropRequest():
            return result;
          case ContinueChain():
            throw StateError('processException cannot return continueWith');
        }
      } catch (e) {
        currentError = e;
      }
    }
    return DMResult.fail(currentError);
  }

  void close() {
    for (var middleware in middlewares) {
      middleware.close();
    }
  }
}
