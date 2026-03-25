# 🕸️ flncrawly

A robust, fluent web crawling framework for Dart.

## Quick Start

```dart
import 'package:flncrawly/flncrawly.dart';

class BookProcessor extends Processor<Map, Request, HtmlResponse> {
  @override
  List<Request> get startRequests => [
    Request.to('http://books.toscrape.com/'),
  ];

  @override
  Stream<Result<Map, Request>> process(HtmlResponse response) async* {
    for (final node in response.$all('.product_pod')) {
      yield Result.item({
        'title': node.$('h3 a').one()?.attr('title'),
        'price': node.$('.price_color').one()?.text(),
        'url': response.urljoin(node.$('h3 a').one()?.attr('href') ?? ''),
      });
    }
    final next = response.$('.next a').one()?.attr('href');
    if (next != null) yield Result.follow(response.follow(next));
  }
}

void main() async {
  await Crawly(BookProcessor())
      .downloadWith(DelayMiddleware(Duration(milliseconds: 500)))
      .downloadWith(RetryMiddleware())
      .downloadWith(UserAgentMiddleware())
      .processWith(DepthMiddleware(maxDepth: 3))
      .pipeWith(FilterPipeline((item) => item['title'] != null))
      .pipeWith(JsonFilePipeline('books.json'))
      .pipeWith(LogPipeline('📖 '))
      .crawl();
}
```

## Core Concepts

**Processor** — defines `startRequests` and `process()`:
- `Result.item(data)` → emit to pipelines
- `Result.follow(request)` → schedule new request
- `Result.retry(request)` → retry with backoff
- `Result.error(e)` → report error
- `Result.finish()` → stop crawling

**Selectors**:
```dart
response.$('.css').one()?.text()
response.$all('a').attr('href')
response.$x('//xpath').one()?.text()

response.$path(r'$.jsonpath').text()
response.$jmes('jmespath')?.raw()
```

## Built-in Components

| Downloader Middlewares | Purpose |
|----------------------|---------|
| `UserAgentMiddleware` | Rotate browser User-Agent |
| `DelayMiddleware` | Rate limiting |
| `RetryMiddleware` | Auto-retry on 5xx/429/timeout |
| `H1DownloaderMiddleware` | HTTP/1.1 fetcher (auto-added) |

| Processor Middlewares | Purpose |
|----------------------|---------|
| `DepthMiddleware` | Limit crawl depth |

| Pipelines | Purpose |
|-----------|---------|
| `LogPipeline` | Print items |
| `FilterPipeline` | Drop items failing a test |
| `JsonFilePipeline` | Export to JSON file |
| `FunctionalPipeline` | Pipeline from a closure |

## Fluent Builder

```dart
Crawly(processor)
    .setDispatcher(PriorityDispatcher(maxConcurrent: 5))
    .setDownloader(customDownloader)
    .downloadWith(middleware)
    .processWith(middleware)
    .pipeWith(pipeline)
    .pipeWithAll([pipeline1, pipeline2])
    .build()   // Engine without starting
    .crawl()   // build + start
```

## Architecture

```
[Processor.startRequests] → [Dispatcher] → [Downloader] → [Processor.process]
                                                                ↓
                                                 Result.item   → [Pipeline]s
                                                 Result.follow → [Dispatcher]
                                                 Result.retry  → [Dispatcher]
```
