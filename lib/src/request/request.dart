class Request {
  final Uri url;
  final String method;
  final Map<String, String> headers;
  final List<int>? body;
  final Map<String, dynamic> meta;
  final Map<String, String> cookies;
  final String? encoding;
  final int priority;
  final int retries;
  final bool dontFilter;

  const Request({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.body,
    this.meta = const {},
    this.cookies = const {},
    this.encoding,
    this.priority = 0,
    this.retries = 0,
    this.dontFilter = false,
  });

  factory Request.to(String url) => Request(url: Uri.parse(url));

  String get fingerprint {
    if (body == null || body!.isEmpty) return '$method:$url';
    return '$method:$url:${body.hashCode}';
  }

  Request nextRetry() => copyWith(retries: retries + 1, dontFilter: true);

  Request copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    List<int>? body,
    Map<String, dynamic>? meta,
    Map<String, String>? cookies,
    String? encoding,
    int? priority,
    int? retries,
    bool? dontFilter,
  }) =>
      Request(
        url: url ?? this.url,
        method: method ?? this.method,
        headers: headers ?? this.headers,
        body: body ?? this.body,
        meta: meta ?? this.meta,
        cookies: cookies ?? this.cookies,
        encoding: encoding ?? this.encoding,
        priority: priority ?? this.priority,
        retries: retries ?? this.retries,
        dontFilter: dontFilter ?? this.dontFilter,
      );

  @override
  String toString() => '[$method] $url';
}
