import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Middleware result.
sealed class DMResult<Req extends IRequest, Res extends IResponse> {
  const DMResult();
  factory DMResult.continueWith(Req request) = ContinueChain<Req, Res>;
  factory DMResult.respond(Res response) = ForwardResponse<Req, Res>;
  factory DMResult.reschedule(Req request) = RescheduleRequest<Req, Res>;
  factory DMResult.fail(Object error, [StackTrace? stackTrace]) = ReportError<Req, Res>;
  factory DMResult.drop() = DropRequest<Req, Res>;
}

final class ContinueChain<Req extends IRequest, Res extends IResponse> extends DMResult<Req, Res> {
  final Req request;
  const ContinueChain(this.request);
}

final class ForwardResponse<Req extends IRequest, Res extends IResponse> extends DMResult<Req, Res> {
  final Res response;
  const ForwardResponse(this.response);
}

final class RescheduleRequest<Req extends IRequest, Res extends IResponse> extends DMResult<Req, Res> {
  final Req request;
  const RescheduleRequest(this.request);
}

final class ReportError<Req extends IRequest, Res extends IResponse> extends DMResult<Req, Res> {
  final Object error;
  final StackTrace? stackTrace;
  const ReportError(this.error, [this.stackTrace]);
}

final class DropRequest<Req extends IRequest, Res extends IResponse> extends DMResult<Req, Res> {
  const DropRequest();
}

/// Intercepts requests and responses.
abstract class DownloaderMiddleware<Req extends IRequest, Res extends IResponse> {
  const DownloaderMiddleware();

  /// Called before fetch.
  Future<void> open() async {}

  /// Intercepts request.
  Future<DMResult<Req, Res>> processRequest(Req request) async => DMResult.continueWith(request);

  /// Intercepts response.
  Future<DMResult<Req, Res>> processResponse(Req request, Res response) async => DMResult.respond(response);

  /// Called after fetch.
  void close() {}
}
