import 'dart:async';

import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Defines an interceptor for response processing and extraction.
abstract class ProcessorMiddleware<
  T,
  Req extends Request,
  Res extends Response
> {
  const ProcessorMiddleware();

  /// Modifies or passes through the [Res] (Top-to-Bottom).
  Future<Res> onInput(Res res) async => res;

  /// Transformation following extraction (Bottom-to-Top).
  Stream<PMResult<T, Req>> onOutput(
    Res res,
    Stream<PMResult<T, Req>> results,
  ) => results;

  /// Recovery which returns a replacement stream (Bottom-to-Top).
  Stream<PMResult<T, Req>>? onError(Res res, Object error) => null;

  void close() {}
}
