import 'dart:convert';

import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:http/http.dart' as http;

/// Fetches via HTTP/1.1 with cookie support.
class H1DownloaderMiddleware<Req extends Request, Res extends Response> extends DownloaderMiddleware<Req, Res> {
  final http.Client _httpClient = http.Client();
  final Map<String, String> _sessionCookies = {};

  H1DownloaderMiddleware();

  void clearCookies() => _sessionCookies.clear();

  @override
  Future<DMResult<Req, Res>> processRequest(Req request) async {
    try {
      final response = await _executeRequest(request);
      return DMResult.respond(response);
    } catch (e, s) {
      return DMResult.fail(e, s);
    }
  }

  Future<Res> _executeRequest(Req request) async {
    final httpRequest = http.Request(request.method, request.url);
    httpRequest.headers.addAll(request.headers);

    final mergedCookies = {..._sessionCookies, ...request.cookies};
    if (mergedCookies.isNotEmpty) {
      httpRequest.headers['Cookie'] = mergedCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    if (request.encoding != null) {
      final codec = Encoding.getByName(request.encoding!);
      if (codec != null) httpRequest.encoding = codec;
    }
    if (request.body != null) httpRequest.bodyBytes = request.body!;

    final streamedResponse = await _httpClient.send(httpRequest);
    final httpResponse = await http.Response.fromStream(streamedResponse);

    if (httpResponse.headers['set-cookie'] != null) {
      _parseCookieHeader(httpResponse.headers['set-cookie']!);
    }

    final contentType = (httpResponse.headers['content-type'] ?? '').split(';').first.trim().toLowerCase();

    final textResponse = TextResponse(
      url: request.url,
      status: httpResponse.statusCode,
      headers: httpResponse.headers,
      body: httpResponse.bodyBytes,
      request: request,
      meta: request.meta,
    );

    return switch (contentType) {
          'application/json' => textResponse.json,
          'application/xml' || 'text/xml' => textResponse.xml,
          'text/html' => textResponse.html,
          _ => textResponse,
        }
        as Res;
  }

  void _parseCookieHeader(String setCookieHeader) {
    for (final part in setCookieHeader.split(',')) {
      final nameValue = part.split(';').first.trim();
      final equalsIndex = nameValue.indexOf('=');
      if (equalsIndex != -1) {
        _sessionCookies[nameValue.substring(0, equalsIndex)] = nameValue.substring(equalsIndex + 1);
      }
    }
  }

  @override
  void close() => _httpClient.close();
}
