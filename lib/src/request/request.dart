/// An HTTP request for the crawler.
class Request {
  final Uri url;
  final String method;
  final Map<String, String> headers;
  final Map<String, String> cookies;
  final List<int>? body;
  final String? encoding;
  final int priority;
  final Map<String, dynamic> meta;
  final int retries;
  final bool dontFilter;

  const Request({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.cookies = const {},
    this.body,
    this.encoding,
    this.priority = 0,
    this.meta = const {},
    this.retries = 0,
    this.dontFilter = false,
  });

  /// GET request from a URL string.
  factory Request.to(
    String url, {
    Map<String, String> headers = const {},
    Map<String, String> cookies = const {},
    Map<String, dynamic> meta = const {},
    int priority = 0,
    bool dontFilter = false,
  }) => Request(
    url: Uri.parse(url),
    headers: headers,
    cookies: cookies,
    meta: meta,
    priority: priority,
    dontFilter: dontFilter,
  );

  /// POST request from a URL string.
  factory Request.post(
    String url, {
    List<int>? body,
    String? encoding,
    Map<String, String> headers = const {},
    Map<String, String> cookies = const {},
    Map<String, dynamic> meta = const {},
    int priority = 0,
    bool dontFilter = false,
  }) => Request(
    url: Uri.parse(url),
    method: 'POST',
    body: body,
    encoding: encoding,
    headers: headers,
    cookies: cookies,
    meta: meta,
    priority: priority,
    dontFilter: dontFilter,
  );

  /// Combines [method], [url], and [body] hash for deduplication.
  String get fingerprint {
    if (body == null || body!.isEmpty) return '$method:$url';
    return '$method:$url:${body.hashCode}';
  }

  Request nextRetry() => copyWith(retries: retries + 1);

  Request copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    Map<String, String>? cookies,
    List<int>? body,
    String? encoding,
    int? priority,
    Map<String, dynamic>? meta,
    int? retries,
    bool? dontFilter,
  }) => Request(
    url: url ?? this.url,
    method: method ?? this.method,
    headers: headers ?? this.headers,
    cookies: cookies ?? this.cookies,
    body: body ?? this.body,
    encoding: encoding ?? this.encoding,
    priority: priority ?? this.priority,
    meta: meta ?? this.meta,
    retries: retries ?? this.retries,
    dontFilter: dontFilter ?? this.dontFilter,
  );

  @override
  String toString() => '[$method] $url';
}
