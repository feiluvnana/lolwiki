import 'dart:async';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:flncrawly/src/processor/processor.dart';

/// Intercepts response input and result output.
abstract class ProcessorMiddleware<T, Req extends IRequest, Res extends IResponse> {
  const ProcessorMiddleware();
  Future<void> open() async {}
  FutureOr<Res> onInput(Res r) async => r;
  Stream<Result<T, Req>> onOutput(Res r, Stream<Result<T, Req>> s) => s;
  void close() {}
}
