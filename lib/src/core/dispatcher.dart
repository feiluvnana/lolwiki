import 'dart:async';
import 'dart:math';

import 'package:flncrawly/src/request/request.dart';

/// Orchestrates the flow of requests between the scheduler and the engine.
abstract class Dispatcher<Req extends Request> {
  const Dispatcher();

  /// A stream of requests ready to be downloaded.
  Stream<Req> get stream;

  /// Adds a new request to the crawling queue.
  void push(Req req);

  /// Schedules a request for retry with an appropriate backoff.
  void retry(Req req);

  /// Signals that a request has been processed, freeing up capacity.
  void complete(Req req);

  /// Closes the dispatcher and its associated streams.
  void close();
}

/// The default [Dispatcher] implementation with concurrency control and prioritization.
class DefaultDispatcher<Req extends Request> extends Dispatcher<Req> {
  /// Maximum number of retries per request.
  final int maxRetries;

  /// Maximum number of requests to process in parallel.
  final int maxConcurrent;

  int _activeCount = 0;
  int _pendingRetries = 0;
  final Random _random = Random();
  final Set<String> _seen = <String>{};
  final List<Req> _queue = [];
  final StreamController<Req> _controller = StreamController<Req>();

  /// Creates a [DefaultDispatcher] with configurable [maxRetries] and [maxConcurrent] limits.
  DefaultDispatcher({this.maxRetries = 3, this.maxConcurrent = 10});

  @override
  Stream<Req> get stream => _controller.stream;

  @override
  void push(Req req) {
    if (_controller.isClosed) return;
    if (!req.dontFilter) {
      if (_seen.contains(req.fingerprint)) return;
      _seen.add(req.fingerprint);
    }
    _enqueue(req);
  }

  @override
  void retry(Req req) {
    if (_controller.isClosed || req.retries >= maxRetries) return;
    
    final backoff = pow(2, req.retries).toInt();
    final baseMs = (2000 * backoff) + _random.nextInt((2000 * backoff * 0.2).toInt() + 1);
    
    _pendingRetries++;
    Future.delayed(Duration(milliseconds: baseMs), () {
      _pendingRetries--;
      _enqueue(req.nextRetry() as Req);
    });
  }

  void _enqueue(Req req) {
    if (_controller.isClosed) return;
    
    // Insert into sorted queue (highest priority first)
    int index = _queue.indexWhere((r) => req.priority > r.priority);
    if (index == -1) {
      _queue.add(req);
    } else {
      _queue.insert(index, req);
    }
    
    _dispatchNext();
  }

  void _dispatchNext() {
    while (!_controller.isClosed && _queue.isNotEmpty && _activeCount < maxConcurrent) {
      final req = _queue.removeAt(0);
      _activeCount++;
      _controller.add(req);
    }
  }

  @override
  void complete(Req req) {
    _activeCount--;
    if (_queue.isEmpty && _activeCount == 0 && _pendingRetries == 0 && !_controller.isClosed) {
      close();
    } else {
      _dispatchNext();
    }
  }

  @override
  void close() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
