import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// What the [Processor] yields back to the [Engine].
///
/// ```dart
/// yield Result.item(Book('Dart in Action', '\$29.99'));
/// yield Result.follow(res.follow('/next'));
/// yield Result.finish();
/// ```
sealed class Result<T, Req extends Request> {
  const Result();
  factory Result.item(T item) = ItemResult<T, Req>;
  factory Result.follow(Req request) = FollowResult<T, Req>;
  factory Result.finish() = FinishResult<T, Req>;
  factory Result.retry(Req request) = RetryResult<T, Req>;
  factory Result.error(Object error, [StackTrace? stackTrace]) =
      ErrorResult<T, Req>;
}

class ItemResult<T, Req extends Request> extends Result<T, Req> {
  final T item;
  ItemResult(this.item);
}

class FollowResult<T, Req extends Request> extends Result<T, Req> {
  final Req request;
  FollowResult(this.request);
}

class FinishResult<T, Req extends Request> extends Result<T, Req> {
  const FinishResult();
}

class RetryResult<T, Req extends Request> extends Result<T, Req> {
  final Req request;
  RetryResult(this.request);
}

class ErrorResult<T, Req extends Request> extends Result<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  ErrorResult(this.error, [this.stackTrace]);
}

/// Defines **where** to start and **how** to extract data.
///
/// ```dart
/// class BookProcessor extends Processor<Book, Request, HtmlResponse> {
///   @override
///   List<Request> get startRequests => [
///     Request.to('https://books.toscrape.com/')
///   ];
///
///   @override
///   Stream<Result<Book, Request>> process(HtmlResponse response) async* {
///     for (final node in response.$all('.product_pod')) {
///       yield Result.item(Book(
///         title: node.$('h3 a')?.attr('title') ?? '',
///         price: node.$('.price_color')?.text() ?? '',
///       ));
///     }
///     final next = response.$('.next a')?.attr('href');
///     if (next != null) yield Result.follow(response.follow(next));
///   }
/// }
/// ```
abstract class Processor<T, Req extends Request, Res extends Response> {
  late final Engine<T, Req, Res> engine;
  final List<ProcessorMiddleware<T, Req, Res>> middlewares = [];

  List<Req> get startRequests;
  Stream<Result<T, Req>> process(Res response);

  /// Runs the middleware chain around [process]. Called by the engine.
  Stream<Result<T, Req>> handleResponse(Res response) async* {
    var currentResponse = response;
    var lastCompletedMiddleware = -1;
    try {
      for (var i = 0; i < middlewares.length; i++) {
        currentResponse = await middlewares[i].onInput(currentResponse);
        lastCompletedMiddleware = i;
      }
      var resultStream = process(currentResponse);
      for (var i = middlewares.length - 1; i >= 0; i--) {
        resultStream = middlewares[i].onOutput(currentResponse, resultStream);
      }
      yield* resultStream;
    } catch (e) {
      final recovery = _tryRecover(currentResponse, e, lastCompletedMiddleware);
      if (recovery != null) {
        yield* recovery;
      } else {
        engine.log('[Processor] Unhandled: $e');
      }
    }
  }

  Stream<Result<T, Req>>? _tryRecover(Res response, Object error, int fromIndex) {
    for (var i = fromIndex; i >= 0; i--) {
      final recovery = middlewares[i].onError(response, error);
      if (recovery != null) return recovery;
    }
    return null;
  }

  void close() {
    for (var middleware in middlewares) {
      middleware.close();
    }
  }
}
