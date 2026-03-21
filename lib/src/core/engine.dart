import 'dart:async';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The central orchestrator that drives the entire crawling lifecycle.
class Engine<T, Req extends Request, Res extends Response> {
  final Dispatcher<Req> dispatcher;
  final Downloader<T, Req, Res> downloader;
  final Processor<T, Req, Res> processor;
  final List<Pipeline<T>> pipelines;
  void Function(String msg) log = print;
  final Stats stats = Stats();

  Engine({
    required this.dispatcher,
    required this.downloader,
    required this.processor,
    this.pipelines = const [],
  }) {
    dispatcher.engine = this;
    downloader.engine = this;
    processor.engine = this;
    for (var p in pipelines) {
      p.engine = this;
    }
  }

  final List<Future<void>> _active = [];

  Future<void> start({List<Req> startRequest = const []}) async {
    stats.start = DateTime.now();
    log('Starting crawl with ${startRequest.length} seeds');
    final done = dispatcher.requests.forEach((req) {
      final task = _run(req);
      _active.add(task);
      task.whenComplete(() => _active.remove(task));
    });
    for (final s in startRequest) {
      dispatcher.push(s);
    }
    try {
      await done;
      await Future.wait(_active);
    } finally {
      close();
    }
  }

  void stop() => dispatcher.close();

  void close() {
    dispatcher.close();
    downloader.close();
    processor.close();
    for (var p in pipelines) {
      p.close();
    }
    stats.end = DateTime.now();
    log('Engine stopped. $stats');
  }

  Future<void> _run(Req req) async {
    stats.requests++;
    try {
      final r = await downloader.handle(req);
      switch (r) {
        case ProxyResponse(response: Res res):
          stats.successes++;
          await for (final reslt in processor.handle(res)) {
            await _handleResult(reslt);
          }
        case RescheduleRequest(request: Req r):
          stats.rescheduled++;
          dispatcher.push(r);
        case ReportError(:final error, :final stackTrace):
          stats.failures++;
          log('Downloader Error: $error');
          if (stackTrace != null) log(stackTrace.toString());
        case IgnoreResult():
          stats.ignored++;
          return;
        case NextRequest():
          throw StateError('Downloader: Invalid return');
      }
    } catch (e, s) {
      stats.failures++;
      log('Engine Failure: $e\n$s');
    } finally {
      dispatcher.complete(req);
    }
  }

  Future<void> _handleResult(PMResult<T, Req> r) async {
    switch (r) {
      case Item<T, Req>(:final item):
        stats.items++;
        T? cur = item;
        for (final p in pipelines) {
          if (cur == null) break;
          cur = await p.handle(cur);
        }
      case Follow<T, Req>(:final request):
        stats.followed++;
        dispatcher.push(request);
      case Retry<T, Req>(:final request):
        stats.retries++;
        dispatcher.retry(request);
      case Error<T, Req>(:final error, :final stackTrace):
        stats.failures++;
        log('Processor Result Error: $error');
        if (stackTrace != null) log(stackTrace.toString());
      case Finish<T, Req>():
        dispatcher.close();
    }
  }
}

class Stats {
  int requests = 0, successes = 0, failures = 0, items = 0;
  int retries = 0, followed = 0, ignored = 0, rescheduled = 0;

  DateTime? start, end;
  Duration? get duration =>
      (start != null && end != null) ? end!.difference(start!) : null;

  @override
  String toString() =>
      'Stats(reqs: $requests, ok: $successes, fail: $failures, items: $items, '
      'retries: $retries, followed: $followed, ignored: $ignored, rescheduled: $rescheduled, '
      'time: ${duration?.inSeconds}s)';
}
