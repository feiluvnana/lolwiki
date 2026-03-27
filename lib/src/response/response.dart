import 'dart:convert';
import 'dart:typed_data';

import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/html_response.dart';
import 'package:flncrawly/src/response/json_response.dart';
import 'package:flncrawly/src/response/xml_response.dart';

/// Represents a crawl response.
abstract interface class IResponse {
  Uri get url;
  int get status;
  Uint8List get body;
  Map<String, dynamic> get headers;
  IRequest get request;
  Map<String, dynamic> get meta;

  /// Resolves a path against the current URL.
  Uri urljoin(String path);

  /// Creates a follow-up request.
  IRequest follow(String path);
}

/// Default [IResponse] implementation.
class Response implements IResponse {
  @override
  final Uri url;
  @override
  final int status;
  @override
  final Uint8List body;
  @override
  final Map<String, dynamic> headers;
  @override
  final IRequest request;
  @override
  final Map<String, dynamic> meta;

  const Response({
    required this.url,
    required this.status,
    required this.body,
    this.headers = const {},
    required this.request,
    this.meta = const {},
  });

  @override
  Uri urljoin(String path) => url.resolve(path);

  @override
  IRequest follow(String path) {
    final req = request;
    if (req is Request) return req.copyWith(url: urljoin(path));
    return Request(url: urljoin(path));
  }
}

/// Base for text-based responses.
class TextResponse extends Response {
  const TextResponse({
    required super.url,
    required super.status,
    required super.body,
    super.headers,
    required super.request,
    super.meta,
  });

  /// Decodes body as UTF-8.
  String get text => utf8.decode(body);

  /// Returns [HtmlResponse] view.
  HtmlResponse get html => HtmlResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );

  /// Returns [XmlResponse] view.
  XmlResponse get xml => XmlResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );

  /// Returns [JsonResponse] view.
  JsonResponse get json => JsonResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );
}
