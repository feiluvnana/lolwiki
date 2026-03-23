import 'dart:async';
import 'dart:math';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/request/request.dart';

/// Default [Dispatcher] with priority ordering, concurrency control,
/// URL deduplication, and exponential backoff retries.
class PriorityDispatcher<Req extends Request> extends Dispatcher<Req> {
  final int maxRetries;
  final int maxConcurrent;

  int _pendingRetries = 0;
  int _activeCount = 0;

  final Set<String> _seenFingerprints = {};
  final List<Req> _queue = [];

  final StreamController<Req> _requestController = StreamController<Req>();
  final StreamController<DispatcherEvent<Req>> _eventController =
      StreamController.broadcast();

  PriorityDispatcher({this.maxRetries = 3, this.maxConcurrent = 10});

  @override
  Stream<Req> get requestStream => _requestController.stream;

  @override
  Stream<DispatcherEvent<Req>> get eventStream => _eventController.stream;

  @override
  void enqueue(Req request) {
    if (_requestController.isClosed) return;
    if (!request.dontFilter && !_seenFingerprints.add(request.fingerprint)) return;
    _eventController.add(DispatcherEvent(DispatcherEventType.enqueued, request));
    _insertSorted(request);
  }

  @override
  void retry(Req request) {
    if (_requestController.isClosed || request.retries >= maxRetries) return;
    _eventController.add(DispatcherEvent(DispatcherEventType.retrying, request));
    _pendingRetries++;
    final backoff = Duration(seconds: pow(2, request.retries).toInt());
    Future.delayed(backoff, () {
      _pendingRetries--;
      _insertSorted(request.nextRetry() as Req);
    });
  }

  void _insertSorted(Req request) {
    _queue.add(request);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    _dispatchNext();
  }

  void _dispatchNext() {
    if (_requestController.isClosed) return;
    while (_queue.isNotEmpty && _activeCount < maxConcurrent) {
      final request = _queue.removeAt(0);
      _activeCount++;
      _eventController.add(DispatcherEvent(DispatcherEventType.dispatched, request));
      _requestController.add(request);
    }
  }

  @override
  void complete(Req request) {
    _activeCount--;
    _eventController.add(DispatcherEvent(DispatcherEventType.completed, request));
    if (_queue.isEmpty && _activeCount == 0 && _pendingRetries == 0) {
      close();
    } else {
      _dispatchNext();
    }
  }

  @override
  void close() {
    if (!_requestController.isClosed) {
      _requestController.close();
      _eventController.close();
    }
  }
}
