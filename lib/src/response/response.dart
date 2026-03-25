import 'dart:typed_data';

import 'package:flncrawly/src/request/request.dart';

/// Standard response for crawl requests.
abstract class Response {
  final Uri url;
  final int status;
  final Map<String, dynamic> headers;
  final Uint8List body;
  final Request request;
  final Map<String, dynamic> meta;

  const Response({
    required this.url,
    required this.status,
    required this.headers,
    required this.body,
    required this.request,
    required this.meta,
  });

  bool get isSuccess => status >= 200 && status < 300;
  bool get isRedirect => status >= 300 && status < 400;
  bool get isError => status >= 400;

  Uri urljoin(String path) => url.resolve(path);

  /// Creates a follow-up [Request] inheriting headers, cookies, and meta.
  /// Resets retries to 0 since this is a new URL, not a retry.
  Request follow(String path, {Map<String, dynamic>? meta}) {
    return request.copyWith(url: urljoin(path), meta: meta ?? this.meta, retries: 0);
  }
}
