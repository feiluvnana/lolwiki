/// 🕸️ flncrawly — Compact, fluent web crawling for Dart.
///
/// ```dart
/// class MyProcessor extends Processor<String, Request, HtmlResponse> {
///   @override
///   List<Request> get startRequests => [Request.to('https://example.com')];
///
///   @override
///   Stream<Result<String, Request>> process(HtmlResponse res) async* {
///     yield Result.item(res.$('title').one()?.text() ?? '');
///   }
/// }
///
/// void main() async => await Crawly(MyProcessor()).pipeWith(LogPipeline()).crawl();
/// ```
library;

export 'src/core/crawly.dart';
export 'src/core/engine.dart';
export 'src/dispatcher/dispatcher.dart';
export 'src/dispatcher/priority_dispatcher.dart';
export 'src/downloader/downloader.dart';
export 'src/downloader/middleware/delay_middleware.dart';
export 'src/downloader/middleware/downloader_middleware.dart';
export 'src/downloader/middleware/h1_downloader_middleware.dart';
export 'src/downloader/middleware/retry_middleware.dart';
export 'src/downloader/middleware/user_agent_middleware.dart';
export 'src/pipeline/filter_pipeline.dart';
export 'src/pipeline/functional_pipeline.dart';
export 'src/pipeline/json_file_pipeline.dart';
export 'src/pipeline/log_pipeline.dart';
export 'src/pipeline/pipeline.dart';
export 'src/processor/middleware/depth_middleware.dart';
export 'src/processor/middleware/processor_middleware.dart';
export 'src/processor/processor.dart';
export 'src/request/request.dart';
export 'src/request/user_agents.dart';
export 'src/response/html_response.dart';
export 'src/response/json_response.dart';
export 'src/response/response.dart';
export 'src/response/xml_response.dart';
