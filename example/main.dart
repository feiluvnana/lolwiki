import 'package:flncrawly/flncrawly.dart';

/// Searches for packages on pub.dev.
class PubSearchProcessor extends Processor<Map<String, String>, Request, HtmlResponse> {
  final String query;
  PubSearchProcessor(this.query);

  @override
  List<Request> get startRequests => [Request.to('https://pub.dev/packages?q=$query')];

  @override
  Stream<Result<Map<String, String>, Request>> process(HtmlResponse res) async* {
    for (final pkg in res.$('.packages .packages-item').all().take(5)) {
      final link = pkg.$('.packages-title a').one();
      if (link == null) continue;

      yield Result.item({
        'name': link.text(),
        'url': res.urljoin(link.attr('href')).toString(),
        'description': pkg.$('.packages-description').one()?.text() ?? '',
      });
    }

    // Follow next page
    final next = res.$('a[rel="next"]').one();
    if (next != null) {
      yield Result.follow(res.follow(next.attr('href')));
    }
  }
}

void main() async {
  print('🔎 Searching pub.dev for "http"...\n');

  await Crawly(PubSearchProcessor('http'))
      .downloadWith(DelayMiddleware(Duration(milliseconds: 500)))
      .downloadWith(RetryMiddleware(maxRetries: 2))
      .downloadWith(UserAgentMiddleware())
      .processWith(DepthMiddleware(maxDepth: 1))
      .pipeWith(FilterPipeline((item) => item['name']?.isNotEmpty ?? false))
      .pipeWith(JsonFilePipeline('results.json'))
      .pipeWith(LogPipeline('📦 '))
      .crawl();
}
