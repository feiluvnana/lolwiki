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

/// Configures and launches a crawl.
/// ```dart
/// await Crawly(MyProcessor()).downloadWith(RetryMiddleware()).crawl();
/// ```
class Crawly<T, Req extends Request, Res extends Response> {
  final Processor<T, Req, Res> _processor;
  Dispatcher<Req>? _dispatcher;
  Downloader<T, Req, Res>? _downloader;
  final List<DownloaderMiddleware<Req, Res>> _downloadMiddlewares = [];
  final List<Pipeline<T>> _pipelines = [];

  Crawly(this._processor);

  Crawly<T, Req, Res> setDispatcher(Dispatcher<Req> dispatcher) {
    _dispatcher = dispatcher;
    return this;
  }

  Crawly<T, Req, Res> setDownloader(Downloader<T, Req, Res> downloader) {
    _downloader = downloader;
    return this;
  }

  Crawly<T, Req, Res> downloadWith(DownloaderMiddleware<Req, Res> middleware) {
    _downloadMiddlewares.add(middleware);
    return this;
  }

  Crawly<T, Req, Res> processWith(ProcessorMiddleware<T, Req, Res> middleware) {
    _processor.middlewares.add(middleware);
    return this;
  }

  Crawly<T, Req, Res> pipeWith(Pipeline<T> pipeline) {
    _pipelines.add(pipeline);
    return this;
  }

  Crawly<T, Req, Res> pipeWithAll(List<Pipeline<T>> pipelines) {
    _pipelines.addAll(pipelines);
    return this;
  }

  Engine<T, Req, Res> build() {
    final downloader =
        _downloader ?? Downloader<T, Req, Res>(middlewares: [..._downloadMiddlewares, H1DownloaderMiddleware()]);
    return Engine<T, Req, Res>(
      dispatcher: _dispatcher ?? PriorityDispatcher<Req>(),
      downloader: downloader,
      processor: _processor,
      pipelines: _pipelines,
    );
  }

  Future<void> crawl() async => build().start();
}
