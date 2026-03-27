import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:http/http.dart' as http;

/// Basic HTTP/1.1 fetcher.
class H1DownloaderMiddleware<Req extends IRequest, Res extends IResponse> extends DownloaderMiddleware<Req, Res> {
  final http.Client _httpClient = http.Client();

  @override
  Future<DMResult<Req, Res>> processRequest(Req request) async {
    try {
      final httpRequest = http.Request(request.method, request.url);
      httpRequest.headers.addAll(request.headers);
      if (request.body != null) httpRequest.bodyBytes = request.body!;

      final streamedResponse = await _httpClient.send(httpRequest);
      final httpResponse = await http.Response.fromStream(streamedResponse);

      final contentType = (httpResponse.headers['content-type'] ?? '').split(';').first.trim().toLowerCase();

      final textResponse = TextResponse(
        url: request.url,
        status: httpResponse.statusCode,
        headers: httpResponse.headers,
        body: httpResponse.bodyBytes,
        request: request,
        meta: request.meta,
      );

      final res = switch (contentType) {
        'application/json' => textResponse.json,
        'application/xml' || 'text/xml' => textResponse.xml,
        'text/html' => textResponse.html,
        _ => textResponse,
      };

      return DMResult.respond(res as Res);
    } catch (e, s) {
      return DMResult.fail(e, s);
    }
  }

  @override
  void close() => _httpClient.close();
}
