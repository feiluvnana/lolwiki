import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/text_response.dart';
import 'package:flncrawly/src/core/downloader.dart';
import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/core/pipeline.dart';
import 'package:flncrawly/src/core/processor.dart';
import 'package:flncrawly/src/core/dispatcher.dart';

/// A fluent builder for configuring and creating an [Engine].
///
/// [T] is the type of items extracted.
/// [Req] and [Res] allow for using custom request and response types.
class Crawly<T, Req extends Request, Res extends TextResponse> {
  Dispatcher<Req>? _dispatcher;
  Downloader<Req, Res>? _downloader;
  Processor<T, Res, Req>? _processor;
  final List<Pipeline<T>> _pipelines = [];

  /// Sets a custom [Dispatcher] for scheduling requests.
  Crawly<T, Req, Res> dispatcher(Dispatcher<Req> dispatcher) {
    _dispatcher = dispatcher;
    return this;
  }

  /// Sets a custom [Downloader] for fetching requests.
  Crawly<T, Req, Res> downloader(Downloader<Req, Res> downloader) {
    _downloader = downloader;
    return this;
  }

  /// Sets the [Processor] that contains your extraction logic.
  Crawly<T, Req, Res> processor(Processor<T, Res, Req> processor) {
    _processor = processor;
    return this;
  }

  /// Adds a [Pipeline] to the execution chain for post-processing extracted items.
  Crawly<T, Req, Res> use(Pipeline<T> pipeline) {
    _pipelines.add(pipeline);
    return this;
  }

  /// Builds and returns a configured [Engine].
  Engine<T, Req, Res> build() {
    return Engine<T, Req, Res>(
      dispatcher: _dispatcher ?? DefaultDispatcher<Req>(),
      downloader: _downloader ?? DefaultDownloader() as Downloader<Req, Res>,
      processor: _processor ?? DefaultProcessor<T>() as Processor<T, Res, Req>,
      pipelines: _pipelines,
    );
  }
}
