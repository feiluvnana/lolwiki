# 🕸️ flncrawly

A robust, minimalist, and developer-friendly web crawling framework for Dart. Built with a modular architecture that separates request scheduling, content downloading, data extraction, and post-processing.

## 🚀 Key Features

*   **Modular Architecture**: Easily swap out Schedulers, Downloaders, or Pipelines.
*   **Built-in Concurrency**: Managed by the Engine's main loop with configurable delays.
*   **Powerful Extraction**: Seamlessly integrate CSS and XPath selectors via `html` and `xpath_selector_html_parser`.
*   **Type-Safe**: Designed with Dart generics to ensure your data items maintain their types from extraction to storage.

## 📦 Installation

Add `flncrawly` to your `pubspec.yaml`:

```yaml
dependencies:
  flncrawly:
    path: ./path/to/flncrawly
```

## 🛠️ Usage Example

Creating a crawler involves defining a `Processor` to extract data and a `Pipeline` to handle that data.

```dart
import 'package:flncrawly/flncrawly.dart';

// 1. Define your data model
class Book {
  final String title;
  Book(this.title);
  @override
  String toString() => 'Book: $title';
}

// 2. Define how to extract data
class BookProcessor extends Processor<Book> {
  @override
  Stream<dynamic> process(Response res) async* {
    if (res is OkResponse) {
      // Use CSS selectors to find elements
      final bookNodes = res.css().getall('.product_pod h3 a');
      
      for (final node in bookNodes.map((e) => e)) {
        yield Book(node.attributes['title'] ?? node.text);
      }

      // Follow pagination
      final nextUrl = res.css().get('li.next a')?.attr('href');
      if (nextUrl != null) {
        yield Request(url: res.urljoin(nextUrl));
      }
    }
  }
}

// 3. Define how to handle extracted data
class MyPipeline extends Pipeline<Book> {
  @override
  Future<void> handle(Book data) async {
    print('Saved book: ${data.title}');
  }
}

void main() async {
  // 4. Initialize and start the engine
  final crawler = Crawly<Book>()
    .processor(BookProcessor())
    .use(MyPipeline())
    .build();

  await crawler.start(seeds: [
    Request(url: Uri.parse('http://books.toscrape.com/')),
  ]);
}
```

## 🧩 Core Concepts

### Engine
The orchestrator. It pulls requests from the **Scheduler**, fetches them via the **Downloader**, hands them to the **Processor**, and broadcasts results to **Pipelines**.

### Request & Response
*   **Request**: A URL combined with a priority level.
*   **Response**: Can be `OkResponse` (with body and selectors) or `FailResponse` (with error and stack trace).

### Selectors
On an `OkResponse`, you can use:
*   `res.css()`: Returns a `CssSelector` for standard CSS queries.
*   `res.xpath()`: Returns an `XPathSelector` for powerful XPath queries.

Both return `ElementMapper` (for single elements) or `ElementAllMapper` (for multiple), providing easy access to `.text()` and `.attr('name')`.

### Scheduler
Manages the crawl queue. The default `PriorityBasedScheduler` handles:
*   **Prioritization**: Processes higher priority requests first.
*   **Duplicate Removal**: Ensures each URL is visited only once.

### Downloader
The networking layer. Defaults to `HttpDownloader` using the standard `http` package.

---

Built with ❤️ for the Dart community.
