import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The result of a logic processor's work.
sealed class PMResult<T, Req extends Request> {
  const PMResult();
  factory PMResult.item(T item) = Item<T, Req>;
  factory PMResult.follow(Req req) = Follow<T, Req>;
  factory PMResult.finish() = Finish<T, Req>;
  factory PMResult.retry(Req req) = Retry<T, Req>;
  factory PMResult.error(Object e, [StackTrace? s]) = Error<T, Req>;
}

class Item<T, Req extends Request> extends PMResult<T, Req> {
  final T item;
  Item(this.item);
}

class Follow<T, Req extends Request> extends PMResult<T, Req> {
  final Req request;
  Follow(this.request);
}

class Finish<T, Req extends Request> extends PMResult<T, Req> {
  const Finish();
}

class Retry<T, Req extends Request> extends PMResult<T, Req> {
  final Req request;
  Retry(this.request);
}

class Error<T, Req extends Request> extends PMResult<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  Error(this.error, [this.stackTrace]);
}

/// Defines core response extraction and its internal middleware chain.
abstract class Processor<T, Req extends Request, Res extends Response> {
  late final Engine<T, Req, Res> engine;
  final List<ProcessorMiddleware<T, Req, Res>> middlewares = [];

  Stream<PMResult<T, Req>> process(Res res);

  Stream<PMResult<T, Req>> handle(Res res) async* {
    var curRes = res;
    int idx = -1;
    try {
      for (var i = 0; i < middlewares.length; i++, idx++) {
        curRes = await middlewares[i].onInput(curRes);
      }
      var resStream = process(curRes);
      for (var i = middlewares.length - 1; i >= 0; i--) {
        resStream = middlewares[i].onOutput(curRes, resStream);
      }
      yield* resStream;
    } catch (e) {
      final recovery = _handleErr(curRes, e, idx < 0 ? middlewares.length - 1 : idx);
      if (recovery != null) yield* recovery;
      else engine.log('[Processor] Discarded: $e');
    }
  }

  Stream<PMResult<T, Req>>? _handleErr(Res res, Object e, int si) {
    for (var i = si; i >= 0; i--) {
      final s = middlewares[i].onError(res, e);
      if (s != null) return s;
    }
    return null;
  }

  void close() => middlewares.forEach((m) => m.close());
}
