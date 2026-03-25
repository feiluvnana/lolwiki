import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';

/// Schedules and deduplicates requests.
abstract class Dispatcher<Req extends Request> {
  late final Engine engine;

  /// Stream of scheduler events.
  Stream<DispatcherEvent<Req>> get eventStream;

  /// Stream of ready requests.
  Stream<Req> get requestStream;

  void enqueue(Req request);
  void retry(Req request);
  void complete(Req request);
  void close();
}

/// Dispatcher status events.
enum DispatcherEventType { enqueued, dispatched, retrying, completed }

/// Recorded scheduler event.
class DispatcherEvent<Req extends Request> {
  final DispatcherEventType type;
  final Req request;
  final DateTime timestamp;

  DispatcherEvent(this.type, this.request) : timestamp = DateTime.now();

  @override
  String toString() => '${type.name.toUpperCase()}: ${request.url}';
}
