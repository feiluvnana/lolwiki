import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// What a [DownloaderMiddleware] returns to control the download chain.
///
/// ```dart
/// DMResult.continueWith(modifiedRequest)  // pass to next middleware
/// DMResult.respond(cachedResponse)        // short-circuit with response
/// DMResult.reschedule(request)            // requeue for later
/// DMResult.fail(error)                    // report an error
/// DMResult.drop()                         // silently discard
/// ```
sealed class DMResult<Req extends Request, Res extends Response> {
  const DMResult();
  factory DMResult.continueWith(Req request) = ContinueChain<Req, Res>;
  factory DMResult.respond(Res response) = ForwardResponse<Req, Res>;
  factory DMResult.reschedule(Req request) = RescheduleRequest<Req, Res>;
  factory DMResult.fail(Object error, [StackTrace? stackTrace]) = ReportError<Req, Res>;
  factory DMResult.drop() = DropRequest<Req, Res>;
}

final class ContinueChain<Req extends Request, Res extends Response> extends DMResult<Req, Res> {
  final Req request;
  const ContinueChain(this.request);
}

final class ForwardResponse<Req extends Request, Res extends Response> extends DMResult<Req, Res> {
  final Res response;
  const ForwardResponse(this.response);
}

final class RescheduleRequest<Req extends Request, Res extends Response> extends DMResult<Req, Res> {
  final Req request;
  const RescheduleRequest(this.request);
}

final class ReportError<Req extends Request, Res extends Response> extends DMResult<Req, Res> {
  final Object error;
  final StackTrace? stackTrace;
  const ReportError(this.error, [this.stackTrace]);
}

final class DropRequest<Req extends Request, Res extends Response> extends DMResult<Req, Res> {
  const DropRequest();
}

/// Intercepts requests before downloading and responses after.
///
/// ```
/// Request → [processRequest] → Network
///                                  ↓
/// Engine ← [processResponse] ← Response
///           or
/// Engine ← [processException] ← Error
/// ```
abstract class DownloaderMiddleware<Req extends Request, Res extends Response> {
  const DownloaderMiddleware();

  Future<DMResult<Req, Res>> processRequest(Req request) async => DMResult.continueWith(request);

  Future<DMResult<Req, Res>> processResponse(Req request, Res response) async => DMResult.respond(response);

  Future<DMResult<Req, Res>> processException(Req request, Object exception) async => DMResult.fail(exception);

  void close() {}
}
