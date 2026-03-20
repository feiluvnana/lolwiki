import 'dart:convert';

import 'package:flncrawly/src/response/response.dart';

/// A response containing decoded textual content.
class TextResponse extends Response {
  /// Creates a new [TextResponse] instance.
  const TextResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// The response body decoded as a UTF-8 string.
  String get text => utf8.decode(body);
}
