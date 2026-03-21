import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/dispatcher/priority_dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/downloader/middleware/h1_downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// A fluent builder for configuring and running a crawl.
class Crawly<T, Req extends Request, Res extends Response> {
  final Processor<T, Req, Res> _processor;
  Dispatcher<Req>? _dispatcher;
  Downloader<T, Req, Res>? _downloader;
  final List<DownloaderMiddleware<Req, Res>> _downloaderMiddlewares = [];
  final List<Pipeline<T>> _pipelines = [];

  Crawly(this._processor);

  static Crawly<T, Req, Res> withProcessor<
    T,
    Req extends Request,
    Res extends Response
  >(Processor<T, Req, Res> p) => Crawly<T, Req, Res>(p);

  Crawly<T, Req, Res> withScheduler(Dispatcher<Req> d) {
    _dispatcher = d;
    return this;
  }

  Crawly<T, Req, Res> withDownloader(Downloader<T, Req, Res> d) {
    _downloader = d;
    return this;
  }

  Crawly<T, Req, Res> addDownloaderMiddleware(
    DownloaderMiddleware<Req, Res> m,
  ) {
    _downloaderMiddlewares.add(m);
    return this;
  }

  Crawly<T, Req, Res> addProcessorMiddleware(
    ProcessorMiddleware<T, Req, Res> m,
  ) {
    _processor.middlewares.add(m);
    return this;
  }

  Crawly<T, Req, Res> addProcessorMiddlewares(
    List<ProcessorMiddleware<T, Req, Res>> mws,
  ) {
    _processor.middlewares.addAll(mws);
    return this;
  }

  Crawly<T, Req, Res> addPipeline(Pipeline<T> p) {
    _pipelines.add(p);
    return this;
  }

  Crawly<T, Req, Res> addPipelines(List<Pipeline<T>> ps) {
    _pipelines.addAll(ps);
    return this;
  }

  Engine<T, Req, Res> build() {
    final downloader =
        _downloader ??
        Downloader<T, Req, Res>(
          middlewares: [..._downloaderMiddlewares, H1DownloaderMiddleware()],
        );

    return Engine<T, Req, Res>(
      dispatcher: _dispatcher ?? PriorityDispatcher<Req>(),
      downloader: downloader,
      processor: _processor,
      pipelines: _pipelines,
    );
  }

  Future<void> run({List<Req> seeds = const []}) async =>
      build().start(startRequest: seeds);
}
