import 'dart:async';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Orchestrates [Dispatcher], [Downloader], [Processor], and [Pipeline]s.
///
/// ```
/// [Processor.startRequests] → [Dispatcher] → [Downloader] → [Processor.process]
///                                                                 ↓
///                                                  Result.item   → [Pipeline]s
///                                                  Result.follow → [Dispatcher]
///                                                  Result.retry  → [Dispatcher]
/// ```
class Engine<T, Req extends Request, Res extends Response> {
  final Dispatcher<Req> dispatcher;
  final Downloader<T, Req, Res> downloader;
  final Processor<T, Req, Res> processor;
  final List<Pipeline<T>> pipelines;
  void Function(String message) log = print;
  final CrawlStats stats = CrawlStats();
  bool _closed = false;

  Engine({
    required this.dispatcher,
    required this.downloader,
    required this.processor,
    this.pipelines = const [],
  }) {
    dispatcher.engine = this;
    downloader.engine = this;
    processor.engine = this;
    for (var pipeline in pipelines) {
      pipeline.engine = this;
    }
  }

  final List<Future<void>> _runningTasks = [];

  Future<void> start() async {
    stats.startTime = DateTime.now();
    log('Starting crawl with ${processor.startRequests.length} requests');

    final streamDone = dispatcher.requestStream.forEach((request) {
      final task = _downloadAndProcess(request);
      _runningTasks.add(task);
      task.whenComplete(() => _runningTasks.remove(task));
    });

    for (final request in processor.startRequests) {
      dispatcher.enqueue(request);
    }

    try {
      await streamDone;
      await Future.wait(_runningTasks);
    } finally {
      close();
    }
  }

  void stop() => dispatcher.close();

  /// Idempotent — safe to call multiple times.
  void close() {
    if (_closed) return;
    _closed = true;
    dispatcher.close();
    downloader.close();
    processor.close();
    for (var pipeline in pipelines) {
      pipeline.close();
    }
    stats.endTime = DateTime.now();
    log('Engine stopped. $stats');
  }

  Future<void> _downloadAndProcess(Req request) async {
    stats.totalRequests++;
    try {
      final downloadResult = await downloader.fetch(request);
      switch (downloadResult) {
        case ForwardResponse(response: Res response):
          stats.successCount++;
          await for (final result in processor.handleResponse(response)) {
            await _routeResult(result);
          }
        case RescheduleRequest(request: Req rescheduled):
          stats.rescheduledCount++;
          dispatcher.enqueue(rescheduled);
        case ReportError(:final error, :final stackTrace):
          stats.failureCount++;
          log('Download Error: $error');
          if (stackTrace != null) log(stackTrace.toString());
        case DropRequest():
          stats.droppedCount++;
        case ContinueChain():
          throw StateError('Downloader returned ContinueChain — misconfigured');
      }
    } catch (e, s) {
      stats.failureCount++;
      log('Engine Error: $e\n$s');
    } finally {
      dispatcher.complete(request);
    }
  }

  Future<void> _routeResult(Result<T, Req> result) async {
    switch (result) {
      case ItemResult<T, Req>(:final item):
        stats.itemCount++;
        T? current = item;
        for (final pipeline in pipelines) {
          if (current == null) break;
          try {
            current = await pipeline.handle(current);
          } catch (e) {
            log('Pipeline Error: $e');
            current = null;
          }
        }
      case FollowResult<T, Req>(:final request):
        stats.followedCount++;
        dispatcher.enqueue(request);
      case RetryResult<T, Req>(:final request):
        stats.retryCount++;
        dispatcher.retry(request);
      case ErrorResult<T, Req>(:final error, :final stackTrace):
        stats.failureCount++;
        log('Process Error: $error');
        if (stackTrace != null) log(stackTrace.toString());
      case FinishResult<T, Req>():
        dispatcher.close();
    }
  }
}

class CrawlStats {
  int totalRequests = 0, successCount = 0, failureCount = 0, itemCount = 0;
  int retryCount = 0, followedCount = 0, droppedCount = 0, rescheduledCount = 0;
  DateTime? startTime, endTime;

  Duration? get duration =>
      (startTime != null && endTime != null) ? endTime!.difference(startTime!) : null;

  @override
  String toString() =>
      'CrawlStats(requests: $totalRequests, success: $successCount, '
      'failures: $failureCount, items: $itemCount, retries: $retryCount, '
      'followed: $followedCount, dropped: $droppedCount, '
      'rescheduled: $rescheduledCount, time: ${duration?.inSeconds}s)';
}
