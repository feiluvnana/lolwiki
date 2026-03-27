import 'dart:async';
import 'dart:collection';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/request/request.dart';

/// Default dispatcher with deduplication.
class PriorityDispatcher<Req extends IRequest> extends Dispatcher<Req> {
  final Set<String> _seen = {};
  final Queue<Req> _queue = Queue<Req>();

  @override
  Future<void> close() async {
    _queue.clear();
    await super.close();
  }

  @override
  Future<bool> push(Req request) async {
    if (!_seen.add(request.fingerprint)) return false;
    _queue.add(request);
    return true;
  }

  @override
  Future<Req?> pull() async {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }
}
