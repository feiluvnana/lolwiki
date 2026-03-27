# 🕸️ flncrawly

A robust, fluent web crawling framework for Dart. Simplified, interface-driven, and pull-based.

## Quick Start

```dart
import 'package:flncrawly/flncrawly.dart';

class PubSearchProcessor extends Processor<Map<String, String>, IRequest, IResponse> {
  final String query;
  PubSearchProcessor(this.query);

  @override
  List<IRequest> get startRequests => [
        Request.to('https://pub.dev/packages?q=$query'),
      ];

  @override
  Stream<Result<Map<String, String>, IRequest>> process(IResponse response) async* {
    if (response is! HtmlResponse) return;

    // .all() returns Iterable<HtmlSelection>
    for (final item in response.$('.package-list .item').all()) {
      yield Result.item({
        'name': item.$('.title a').one()?.text() ?? 'Unknown',
        'url': response.urljoin(item.$('.title a').one()?.attr('href') ?? '').toString(),
      });
    }

    final next = response.$('.pagination .next').one()?.attr('href');
    if (next != null) yield Result.follow(response.follow(next));
  }
}

void main() async {
  await Crawly(PubSearchProcessor('http'))
      .downloadWith(UserAgentMiddleware())
      .pipeWith(LogPipeline())
      .crawl();
}
```

## Core Concepts

- **`IRequest` / `Request`**: Simple value objects for target URLs and metadata.
- **`IResponse` / `Response`**: Wrappers for HTTP results with fluent selector support.
- **`IProcessor`**: Defines how to extract items and which links to follow.
- **`IDispatcher`**: Handles request queueing and deduplication (Pull-based).
- **`IDownloader`**: Fetches requests via a customizable middleware chain.
- **`Pipeline`**: Processes extracted items (e.g., saving to file).

## Selectors

Every response supports fluent, delayed-execution selectors:

```dart
response.$('.css').one()?.text()
response.$('.items').all() // Returns Iterable<Selection>
response.$x('//xpath').one()?.attr('src')

// JSON/XML Support
response.$path(r'$.jsonpath').one()
response.$jmes('jmespath').one()
```

## Lifecycle

Every component implements `open()` and `close()`:
1. `Engine.open()` calls `open()` on Dispatcher, Downloader, Processor, and Pipelines.
2. `Engine.start()` pulls and processes until the queue is empty.
3. `Engine.close()` ensures all resources are released.

## Architecture

```
[Processor.startRequests] → [Dispatcher]
                                ↓ (pull)
[Pipeline] ← (item) ← [Processor.process] ← [Downloader]
                         ↓ (follow)
                    [Dispatcher]
```
