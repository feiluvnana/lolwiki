/// Represents a crawl request.
abstract interface class IRequest {
  Uri get url;
  String get method;
  Map<String, String> get headers;
  List<int>? get body;
  Map<String, dynamic> get meta;

  /// Unique hash for deduplication.
  String get fingerprint;
}

/// Default [IRequest] implementation.
class Request implements IRequest {
  @override
  final Uri url;
  @override
  final String method;
  @override
  final Map<String, String> headers;
  @override
  final List<int>? body;
  @override
  final Map<String, dynamic> meta;

  const Request({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.body,
    this.meta = const {},
  });

  factory Request.to(String url) => Request(url: Uri.parse(url));

  @override
  String get fingerprint => '$method:$url:${body.hashCode}';

  Request copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    List<int>? body,
    Map<String, dynamic>? meta,
  }) {
    return Request(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() => '[$method] $url';
}
