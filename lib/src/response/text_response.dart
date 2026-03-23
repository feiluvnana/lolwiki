import 'dart:convert';

import 'package:flncrawly/flncrawly.dart';

/// A response containing decoded textual content.
///
/// Provides lazy conversion to typed responses via [html], [xml], and [json]
/// getters.
///
/// ```dart
/// // Access raw text
/// print(res.text);
///
/// // Convert to HTML for querying
/// final htmlRes = res.html;
/// final title = htmlRes.$('title')?.text();
/// ```
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

  /// Converts this response to an [HtmlResponse] for CSS/XPath queries.
  HtmlResponse get html => HtmlResponse(
    url: url,
    status: status,
    headers: headers,
    body: body,
    request: request,
    meta: meta,
  );

  /// Converts this response to an [XmlResponse] for XPath queries.
  XmlResponse get xml => XmlResponse(
    url: url,
    status: status,
    headers: headers,
    body: body,
    request: request,
    meta: meta,
  );

  /// Converts this response to a [JsonResponse] for JSONPath/JMESPath queries.
  JsonResponse get json => JsonResponse(
    url: url,
    status: status,
    headers: headers,
    body: body,
    request: request,
    meta: meta,
  );
}
