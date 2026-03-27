import 'package:flncrawly/flncrawly.dart';

class PubSearchProcessor extends Processor<Map<String, String>, IRequest, IResponse> {
  final String query;
  PubSearchProcessor(this.query);

  @override
  List<IRequest> get startRequests => [
        Request.to('https://pub.dev/packages?q=$query'),
      ];

  @override
  Stream<Result<Map<String, String>, IRequest>> process(IResponse response) async* {
    if (response is! HtmlResponse) return;

    final items = response.$('.package-list .item').all();
    for (final item in items) {
      final title = item.$('.title a').one()?.text() ?? '';
      final version = item.$('.version').one()?.text() ?? '';
      
      yield Result.item({
        'name': title,
        'version': version,
        'url': response.urljoin(item.$('.title a').one()?.attr('href') ?? '').toString(),
      });
    }

    final next = response.$('.pagination .next').one()?.attr('href') ?? '';
    if (next.isNotEmpty) {
      yield Result.follow(response.follow(next));
    }
  }
}

void main() async {
  print('🔎 Searching pub.dev for "http"...\n');

  await Crawly(PubSearchProcessor('http'))
      .downloadWith(UserAgentMiddleware())
      .pipeWith(FilterPipeline((item) => (item['name'] ?? '').isNotEmpty))
      .pipeWith(JsonFilePipeline('results.json'))
      .pipeWith(LogPipeline())
      .crawl();
}
