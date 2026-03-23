import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';

/// Controls request scheduling, deduplication, and concurrency.
abstract class Dispatcher<Req extends Request> {
  late final Engine engine;

  Stream<DispatcherEvent<Req>> get eventStream;
  Stream<Req> get requestStream;

  void enqueue(Req request);
  void retry(Req request);
  void complete(Req request);
  void close();
}

enum DispatcherEventType { enqueued, dispatched, retrying, completed }

class DispatcherEvent<Req extends Request> {
  final DispatcherEventType type;
  final Req request;
  final DateTime timestamp;

  DispatcherEvent(this.type, this.request) : timestamp = DateTime.now();

  @override
  String toString() => '${type.name.toUpperCase()}: ${request.url}';
}
