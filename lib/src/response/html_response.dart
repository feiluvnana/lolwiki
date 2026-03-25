import 'package:flncrawly/src/response/text_response.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// Response with CSS/XPath selection.
class HtmlResponse extends TextResponse {
  const HtmlResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  HtmlSelector get selector => HtmlSelector._(parse(text).documentElement!, []);
  HtmlSelector $(String expr) => selector.$(expr);
  HtmlSelector $x(String expr) => selector.$x(expr);
  HtmlSelection? one() => selector.one();
  HtmlSelections all() => selector.all();
}

enum HtmlSelectorType { css, xpath }

class HtmlSelector {
  final Element element;
  final List<(HtmlSelectorType type, String expr)> selectors;

  const HtmlSelector._(this.element, this.selectors);

  HtmlSelector $(String expr) {
    return HtmlSelector._(element, selectors + [(HtmlSelectorType.css, expr)]);
  }

  HtmlSelector $x(String expr) {
    return HtmlSelector._(element, selectors + [(HtmlSelectorType.xpath, expr)]);
  }

  HtmlSelection? one() {
    Element? e = element;
    for (final (type, expr) in selectors) {
      switch (type) {
        case HtmlSelectorType.css:
          e = e?.querySelector(expr);
        case HtmlSelectorType.xpath:
          final node = e == null ? null : HtmlXPath.node(e).query(expr).node?.node;
          if (node is! Element) return null;
          e = node;
      }
      if (e == null) return null;
    }
    return HtmlSelection._(e!);
  }

  HtmlSelections all() {
    Iterable<Element> e = [element];
    for (final (type, expr) in selectors) {
      switch (type) {
        case HtmlSelectorType.css:
          e = e.expand((e) => e.querySelectorAll(expr));
        case HtmlSelectorType.xpath:
          e = e.expand((e) => HtmlXPath.node(e).query(expr).nodes.map((m) => m.node).whereType<Element>());
      }
    }
    return HtmlSelections._(e.toList());
  }
}

final class HtmlSelection {
  final Element element;

  const HtmlSelection._(this.element);

  HtmlSelector $(String expr) => HtmlSelector._(element, [(HtmlSelectorType.css, expr)]);
  HtmlSelector $x(String expr) => HtmlSelector._(element, [(HtmlSelectorType.xpath, expr)]);

  String text() => element.text.trim();
  String attr(String name) => (element.attributes[name] ?? '').trim();
}

final class HtmlSelections extends Iterable<HtmlSelection> {
  final List<Element> _elements;
  const HtmlSelections._(this._elements);

  @override
  Iterator<HtmlSelection> get iterator => _elements.map((e) => HtmlSelection._(e)).iterator;

  List<String> text() => map((e) => e.text()).toList();
  List<String> attr(String name) => map((e) => e.attr(name)).toList();
}
