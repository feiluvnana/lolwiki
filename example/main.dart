import 'package:flncrawly/flncrawly.dart';

/// A processor that searches for packages on pub.dev.
class PubSearchProcessor
    extends Processor<Map<String, String>, Request, HtmlResponse> {
  final String query;

  PubSearchProcessor(this.query);

  @override
  Stream<PMResult<Map<String, String>, Request>> process(
    HtmlResponse res,
  ) async* {
    final packages = res.$all('.packages .packages-item');

    for (var i = 0; i < 5 && i < packages.length; i++) {
      final pkg = packages.items[i];
      final titleNode = pkg.$('.packages-title a');

      yield PMResult.item({
        'name': titleNode?.text() ?? 'Unknown',
        'url': res.urljoin(titleNode?.attr('href') ?? '').toString(),
        'description': pkg.$('.packages-description')?.text() ?? '',
      });
    }

    // Follow next page
    final nextLink = res.$('a[rel="next"]');
    if (nextLink != null) {
      final href = nextLink.attr('href');
      yield PMResult.follow(res.follow(href));
    }
  }
}

void main() async {
  final query = 'http';
  final processor = PubSearchProcessor(query);

  // Correct abstract Processor design with internal middleware engine
  final crawler = Crawly.withProcessor(processor)
      .addDownloaderMiddleware(UserAgentMiddleware())
      .addProcessorMiddleware(DepthMiddleware(maxDepth: 1))
      .addPipeline(LogPipeline('📦 '));

  print('🔎 Searching pub.dev for "$query"...\n');

  await crawler.run(
    seeds: [Request(url: Uri.parse('https://pub.dev/packages?q=$query'))],
  );
}
