import 'dart:async';

import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Intercepts responses before/after the [Processor].
///
/// ```
/// [onInput]  (Top→Bottom) → [Processor.process] → [onOutput] (Bottom→Top)
///                                                   [onError]  (Bottom→Top)
/// ```
abstract class ProcessorMiddleware<
  T,
  Req extends Request,
  Res extends Response
> {
  const ProcessorMiddleware();

  Future<Res> onInput(Res response) async => response;

  Stream<Result<T, Req>> onOutput(
    Res response,
    Stream<Result<T, Req>> results,
  ) => results;

  /// Return a recovery stream, or `null` to propagate the error.
  Stream<Result<T, Req>>? onError(Res response, Object error) => null;

  void close() {}
}
