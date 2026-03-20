import 'package:flncrawly/src/core/dispatcher.dart';
import 'package:flncrawly/src/core/downloader.dart';
import 'package:flncrawly/src/core/pipeline.dart';
import 'package:flncrawly/src/core/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/text_response.dart';

/// The core orchestrator that drives the entire crawling process.
///
/// [T] is the type of data item being extracted.
/// [Req] and [Res] allow for customized request and response types.
class Engine<T, Req extends Request, Res extends TextResponse> {
  /// The [Dispatcher] responsible for request scheduling.
  final Dispatcher<Req> dispatcher;

  /// The [Downloader] responsible for network communication.
  final Downloader<Req, Res> downloader;

  /// The [Processor] that extracts data and instructions from responses.
  final Processor<T, Res, Req> processor;

  /// A list of [Pipeline]s for post-processing extracted items.
  final List<Pipeline<T>> pipelines;

  /// Creates a new [Engine] with the required components.
  Engine({required this.dispatcher, required this.downloader, required this.processor, required this.pipelines});

  final List<Future<void>> _active = [];

  /// Starts the crawling process using the provided [seeds] as entry points.
  ///
  /// This method returns when the crawl is finished (i.e., when there are no more
  /// pending requests or when a [Finish] instruction is received).
  Future<void> start({required List<Req> seeds}) async {
    print('Starting engine with ${seeds.length} seeds');

    final loop = () async {
      await for (final req in dispatcher.stream) {
        final task = _run(req);
        _active.add(task);
        task.whenComplete(() => _active.remove(task));
      }
    }();

    seeds.forEach(dispatcher.push);

    await loop;
    await Future.wait(_active);

    print('Engine stopped');
  }

  Future<void> _run(Req req) async {
    try {
      final res = await downloader.download(req);

      await for (final output in processor.process(res)) {
        switch (output) {
          case Item<T, Req>(:final item):
            await _feedPipelines(item);
          case Follow<T, Req>(:final request):
            dispatcher.push(request);
          case Retry<T, Req>(:final request):
            dispatcher.retry(request);
          case Error<T, Req>(:final error, :final stackTrace):
            print('Error: $error');
            if (stackTrace != null) print(stackTrace);
          case Finish<T, Req>():
            dispatcher.close();
        }
      }
    } catch (e, s) {
      print('Execution error: $e');
      print(s);
    } finally {
      dispatcher.complete(req);
    }
  }

  Future<void> _feedPipelines(T item) async {
    T? current = item;
    for (final pipeline in pipelines) {
      if (current == null) break;
      current = await pipeline.handle(current);
    }
  }
}
