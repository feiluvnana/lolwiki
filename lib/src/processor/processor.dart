import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Process result (item, request, or control).
sealed class Result<T, Req extends IRequest> {
  const Result();
  factory Result.item(T item) = ItemResult<T, Req>;
  factory Result.follow(Req request) = FollowResult<T, Req>;
  factory Result.finish() = FinishResult<T, Req>;
  factory Result.error(Object error, [StackTrace? stackTrace]) = ErrorResult<T, Req>;
}

class ItemResult<T, Req extends IRequest> extends Result<T, Req> {
  final T item;
  ItemResult(this.item);
}

class FollowResult<T, Req extends IRequest> extends Result<T, Req> {
  final Req request;
  FollowResult(this.request);
}

class FinishResult<T, Req extends IRequest> extends Result<T, Req> {
  const FinishResult();
}

class ErrorResult<T, Req extends IRequest> extends Result<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  ErrorResult(this.error, [this.stackTrace]);
}

/// Extracts items or follows from responses.
abstract interface class IProcessor<T, Req extends IRequest, Res extends IResponse> {
  set engine(Engine<T, Req, Res> engine);

  /// Initializes processor.
  Future<void> open();

  /// Initial requests to queue.
  List<Req> get startRequests;

  /// Orchestrates processing.
  Stream<Result<T, Req>> handleResponse(Res response);

  /// Finalizes processor.
  Future<void> close();
}

/// Template processor with middleware support.
abstract class Processor<T, Req extends IRequest, Res extends IResponse> implements IProcessor<T, Req, Res> {
  @override
  late Engine<T, Req, Res> engine;
  final List<ProcessorMiddleware<T, Req, Res>> middlewares = [];

  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {
    for (var m in middlewares) {
      m.close();
    }
  }

  /// Extracts results from response.
  Stream<Result<T, Req>> process(Res response);

  @override
  Stream<Result<T, Req>> handleResponse(Res response) async* {
    var raw = process(response);
    for (var i = middlewares.length - 1; i >= 0; i--) {
      raw = middlewares[i].onOutput(response, raw);
    }
    yield* raw;
  }
}
