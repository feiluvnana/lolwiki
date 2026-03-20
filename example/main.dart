import 'package:flncrawly/flncrawly.dart';

class PubDevProcessor extends Processor<Map<String, dynamic>, TextResponse, Request> {
  @override
  Stream<ProcessorOutput<Map<String, dynamic>, Request>> process(TextResponse res) async* {
    if (res is HtmlResponse) {
      final blocks = res.$all("div.home-block").map((e) {
        return {
          "section": e.$(".home-block-title")?.text(),
          "packages": e.$all(".mini-list-item-title-text").text()
        };
      });
      yield ProcessorOutput.item({"value": blocks});
    }
  }
}

void main() async {
  final crawler = Crawly<Map<String, dynamic>, Request, TextResponse>()
      .processor(PubDevProcessor())
      .build();
  await crawler.start(seeds: [Request(url: Uri.parse("https://pub.dev"))]);
}
