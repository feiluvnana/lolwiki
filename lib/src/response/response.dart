import 'dart:convert';
import 'dart:typed_data';

import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/html_response.dart';
import 'package:flncrawly/src/response/json_response.dart';
import 'package:flncrawly/src/response/xml_response.dart';

class Response {
  final Uri url;
  final int status;
  final Uint8List body;
  final Map<String, dynamic> headers;
  final Request request;
  final Map<String, dynamic> meta;

  const Response({
    required this.url,
    required this.status,
    required this.body,
    this.headers = const {},
    required this.request,
    this.meta = const {},
  });

  Uri urljoin(String path) => url.resolve(path);

  Request follow(String path) => request.copyWith(
        url: urljoin(path),
        cookies: request.cookies,
      );
}

class TextResponse extends Response {
  const TextResponse({
    required super.url,
    required super.status,
    required super.body,
    super.headers,
    required super.request,
    super.meta,
  });

  String get text => utf8.decode(body);

  HtmlResponse get html => HtmlResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );

  XmlResponse get xml => XmlResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );

  JsonResponse get json => JsonResponse(
        url: url,
        status: status,
        body: body,
        headers: headers,
        request: request,
        meta: meta,
      );
}
