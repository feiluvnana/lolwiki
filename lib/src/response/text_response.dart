import 'dart:convert';

import 'package:flncrawly/src/response/html_response.dart';
import 'package:flncrawly/src/response/json_response.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:flncrawly/src/response/xml_response.dart';

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

  HtmlResponse get html =>
      HtmlResponse(url: url, status: status, body: body, headers: headers, request: request, meta: meta);

  XmlResponse get xml =>
      XmlResponse(url: url, status: status, body: body, headers: headers, request: request, meta: meta);

  JsonResponse get json =>
      JsonResponse(url: url, status: status, body: body, headers: headers, request: request, meta: meta);
}
