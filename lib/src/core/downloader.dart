import 'dart:convert';

import 'package:flncrawly/flncrawly.dart';
import 'package:http/http.dart' as http;

abstract class Downloader<Req extends Request, Res extends Response> {
  const Downloader();

  Future<Res> download(Req req);
}

class DefaultDownloader extends Downloader<Request, TextResponse> {
  final http.Client _client = http.Client();

  DefaultDownloader();

  @override
  Future<TextResponse> download(Request req) async {
    final request = http.Request(req.method, req.url);
    request.headers.addAll(req.headers);
    if (req.cookies.isNotEmpty) {
      final cookieString = req.cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      request.headers['Cookie'] = cookieString;
    }
    if (req.encoding != null) {
      final codec = Encoding.getByName(req.encoding!);
      if (codec != null) request.encoding = codec;
    }
    if (req.body != null) {
      request.bodyBytes = req.body!;
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    
    if (contentType.contains('application/json')) {
      return JsonResponse(
        request: req,
        body: response.bodyBytes,
        url: req.url,
        status: response.statusCode,
        headers: response.headers,
        meta: req.meta,
      );
    }

    if (contentType.contains('text/html')) {
      return HtmlResponse(
        request: req,
        body: response.bodyBytes,
        url: req.url,
        status: response.statusCode,
        headers: response.headers,
        meta: req.meta,
      );
    }

    return TextResponse(
      request: req,
      body: response.bodyBytes,
      url: req.url,
      status: response.statusCode,
      headers: response.headers,
      meta: req.meta,
    );
  }
}
