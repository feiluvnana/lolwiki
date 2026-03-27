import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/downloader/middleware/h1_downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Configures and launches a crawl.
class Crawly<T, Req extends IRequest, Res extends IResponse> {
  final IProcessor<T, Req, Res> _processor;
  IDispatcher<Req>? _dispatcher;
  IDownloader<Req, Res>? _downloader;
  final List<DownloaderMiddleware<Req, Res>> _downloadMiddlewares = [];
  final List<Pipeline<T>> _pipelines = [];

  Crawly(this._processor);

  Crawly<T, Req, Res> setDispatcher(IDispatcher<Req> d) {
    _dispatcher = d;
    return this;
  }

  Crawly<T, Req, Res> setDownloader(IDownloader<Req, Res> d) {
    _downloader = d;
    return this;
  }

  Crawly<T, Req, Res> downloadWith(DownloaderMiddleware<Req, Res> m) {
    _downloadMiddlewares.add(m);
    return this;
  }

  Crawly<T, Req, Res> processWith(ProcessorMiddleware<T, Req, Res> m) {
    if (_processor is Processor<T, Req, Res>) {
      _processor.middlewares.add(m);
    }
    return this;
  }

  Crawly<T, Req, Res> pipeWith(Pipeline<T> p) {
    _pipelines.add(p);
    return this;
  }

  Engine<T, Req, Res> build() {
    final downloader =
        _downloader ?? Downloader<Req, Res>(middlewares: [..._downloadMiddlewares, H1DownloaderMiddleware<Req, Res>()]);

    return Engine<T, Req, Res>(
      dispatcher: _dispatcher ?? Dispatcher<Req>(),
      downloader: downloader,
      processor: _processor,
      pipelines: _pipelines,
    );
  }

  /// Starts the crawl.
  Future<void> crawl() async => build().start();
}
