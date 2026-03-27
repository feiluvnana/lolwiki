import 'dart:async';
import 'dart:collection';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';

/// Schedules and deduplicates requests.
abstract interface class IDispatcher<Req extends IRequest> {
  set engine(Engine engine);

  /// Initializes dispatcher.
  Future<void> open();

  /// Queues a request. Returns true if added.
  Future<bool> push(Req request);

  /// Pulls the next request. Returns null if empty.
  Future<Req?> pull();

  /// Finalizes dispatcher.
  Future<void> close();
}

/// Default in-memory dispatcher with deduplication.
class Dispatcher<Req extends IRequest> implements IDispatcher<Req> {
  @override
  late final Engine engine;
  final Set<String> _seen = {};
  final Queue<Req> _queue = Queue<Req>();

  @override
  Future<void> open() async {}

  @override
  Future<bool> push(Req request) async {
    if (!_seen.add(request.fingerprint)) return false;
    _queue.add(request);
    return true;
  }

  @override
  Future<Req?> pull() async => _queue.isEmpty ? null : _queue.removeFirst();

  @override
  Future<void> close() async => _queue.clear();
}
