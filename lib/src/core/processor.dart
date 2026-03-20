import 'package:flncrawly/flncrawly.dart';

/// Instructions returned by a [Processor] to the [Engine] during crawling.
/// [T] is the type of item extracted.
/// [Req] is the type of [Request] being followed or retried.
sealed class ProcessorOutput<T, Req extends Request> {
  const ProcessorOutput();

  /// Emits an extracted data item of type [T].
  static Item<T, Req> item<T, Req extends Request>(T item) => Item<T, Req>(item);

  /// Requests the engine to schedule a new [Request] for crawling.
  static Follow<T, Req> follow<T, Req extends Request>(Req req) => Follow<T, Req>(req);

  /// Commands the engine to stop the crawl immediately.
  static Finish<T, Req> finish<T, Req extends Request>() => Finish<T, Req>();

  /// Requests the engine to retry a [Request].
  static Retry<T, Req> retry<T, Req extends Request>(Req req) => Retry<T, Req>(req);

  /// Reports an error encountered during processing.
  static Error<T, Req> error<T, Req extends Request>(Object e, [StackTrace? s]) => Error<T, Req>(e, s);
}

/// A wrapper for an extracted data item.
class Item<T, Req extends Request> extends ProcessorOutput<T, Req> {
  final T item;
  const Item(this.item);
}

/// An instruction to crawl a new [Request].
class Follow<T, Req extends Request> extends ProcessorOutput<T, Req> {
  final Req request;
  const Follow(this.request);
}

/// An instruction to stop the engine.
class Finish<T, Req extends Request> extends ProcessorOutput<T, Req> {
  const Finish();
}

/// An instruction to retry a failed [Request].
class Retry<T, Req extends Request> extends ProcessorOutput<T, Req> {
  final Req request;
  const Retry(this.request);
}

/// An instruction reporting a processing error.
class Error<T, Req extends Request> extends ProcessorOutput<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  const Error(this.error, [this.stackTrace]);
}

/// Defines how to extract items and instructions from a crawl response.
///
/// Implement this class to define your scraping logic.
/// [T] is the type of items being extracted.
/// [Res] is the expected response type (e.g., [HtmlResponse] or [JsonResponse]).
/// [Req] is the custom request type this processor yields in its instructions.
abstract class Processor<T, Res extends TextResponse, Req extends Request> {
  const Processor();

  /// Processes the [Response] and yields extraction instructions.
  /// Any uncaught exceptions will be caught by the engine and reported as errors.
  Stream<ProcessorOutput<T, Req>> process(Res res);
}

/// A basic processor that yields no output.
class DefaultProcessor<T> extends Processor<T, TextResponse, Request> {
  const DefaultProcessor();

  @override
  Stream<ProcessorOutput<T, Request>> process(TextResponse res) async* {}
}

class Book {
  final String title;
  final String price;

  const Book({required this.title, required this.price});

  @override
  String toString() => 'Book(title: $title, price: $price)';
}
