import 'dart:async';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Orchestrates the crawl process.
class Engine<T, Req extends IRequest, Res extends IResponse> {
  final IDispatcher<Req> dispatcher;
  final IDownloader<Req, Res> downloader;
  final IProcessor<T, Req, Res> processor;
  final List<Pipeline<T>> pipelines;
  void Function(String message) log = print;
  final CrawlStats stats = CrawlStats();
  bool _closed = false;

  Engine({required this.dispatcher, required this.downloader, required this.processor, this.pipelines = const []}) {
    dispatcher.engine = this;
    downloader.engine = this;
    processor.engine = this;
    for (var p in pipelines) {
      p.engine = this;
    }
  }

  final List<Future<void>> _runningTasks = [];

  /// Initializes components.
  Future<void> open() async {
    await dispatcher.open();
    await downloader.open();
    await processor.open();
    for (var p in pipelines) {
      await p.open();
    }
  }

  /// Starts the crawl loop.
  Future<void> start() async {
    await open();
    stats.startTime = DateTime.now();
    log('Starting crawl with ${processor.startRequests.length} requests');

    for (final r in processor.startRequests) {
      await dispatcher.push(r);
    }

    while (true) {
      final r = await dispatcher.pull();
      if (r == null) {
        if (_runningTasks.isEmpty) break;
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      final task = _downloadAndProcess(r);
      _runningTasks.add(task);
      task.whenComplete(() => _runningTasks.remove(task));

      if (_runningTasks.length >= 10) {
        await Future.any(_runningTasks);
      }
    }

    try {
      await Future.wait(_runningTasks);
    } finally {
      await close();
    }
  }

  /// Shutdown all components.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await dispatcher.close();
    await downloader.close();
    await processor.close();
    for (var p in pipelines) {
      p.close();
    }
    stats.endTime = DateTime.now();
    log('Engine stopped. $stats');
  }

  Future<void> _downloadAndProcess(Req r) async {
    stats.totalRequests++;
    try {
      final res = await downloader.fetch(r);
      stats.successCount++;
      await for (final result in processor.handleResponse(res)) {
        await _routeResult(result);
      }
    } catch (e, s) {
      stats.failureCount++;
      log('Engine Error: $e\n$s');
    }
  }

  Future<void> _routeResult(Result<T, Req> result) async {
    switch (result) {
      case ItemResult<T, Req>(:final item):
        stats.itemCount++;
        T? current = item;
        for (final p in pipelines) {
          if (current == null) break;
          try {
            current = await p.handle(current);
          } catch (e) {
            log('Pipeline Error: $e');
            current = null;
          }
        }
      case FollowResult<T, Req>(:final request):
        stats.followedCount++;
        await dispatcher.push(request);
      case ErrorResult<T, Req>(:final error, :final stackTrace):
        stats.failureCount++;
        log('Process Error: $error');
        if (stackTrace != null) log(stackTrace.toString());
      case FinishResult<T, Req>():
        await close();
    }
  }
}

class CrawlStats {
  int totalRequests = 0, successCount = 0, failureCount = 0, itemCount = 0;
  int followedCount = 0, droppedCount = 0;
  DateTime? startTime, endTime;

  Duration? get duration => (startTime != null && endTime != null) ? endTime!.difference(startTime!) : null;

  @override
  String toString() => 'CrawlStats(requests: $totalRequests, success: $successCount, failures: $failureCount, items: $itemCount, followed: $followedCount, dropped: $droppedCount, time: ${duration?.inSeconds}s)';
}
