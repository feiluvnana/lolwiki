import 'package:flncrawly/src/response/response.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class XmlResponse extends TextResponse {
  const XmlResponse({
    required super.url,
    required super.status,
    required super.body,
    super.headers,
    required super.request,
    super.meta,
  });

  XmlSelector get selector => XmlSelector._(XmlDocument.parse(text), []);
  XmlSelector $x(String expr) => selector.$x(expr);
  XmlSelection? one() => selector.one();
  XmlSelections all() => selector.all();
}

class XmlSelector {
  final XmlNode node;
  final List<String> selectors;

  const XmlSelector._(this.node, this.selectors);

  XmlSelector $x(String expr) {
    return XmlSelector._(node, selectors + [expr]);
  }

  XmlSelection? one() {
    XmlNode? current = node;
    for (final expr in selectors) {
      // ignore: experimental_member_use
      final match = current?.xpath(expr);
      if (match == null || match.isEmpty) return null;
      current = match.first;
    }
    return XmlSelection._(current!);
  }

  XmlSelections all() {
    Iterable<XmlNode> current = [node];
    for (final expr in selectors) {
      // ignore: experimental_member_use
      current = current.expand((n) => n.xpath(expr));
    }
    return XmlSelections._(current.toList());
  }
}

final class XmlSelection {
  final XmlNode node;

  const XmlSelection._(this.node);

  XmlSelector $x(String expr) => XmlSelector._(node, [expr]);

  String text() => node.innerText.trim();
  String attr(String name) => node is XmlElement ? (node as XmlElement).getAttribute(name)?.trim() ?? '' : '';
  String xml() => node.toXmlString();
}

final class XmlSelections extends Iterable<XmlSelection> {
  final List<XmlNode> nodes;

  const XmlSelections._(this.nodes);

  @override
  Iterator<XmlSelection> get iterator => nodes.map((n) => XmlSelection._(n)).iterator;

  Iterable<XmlSelector> $x(String expr) => nodes.map((n) => XmlSelector._(n, [expr]));

  List<String> text() => map((e) => e.text()).toList();
  List<String> attr(String name) => map((e) => e.attr(name)).toList();
  List<String> xml() => map((e) => e.xml()).toList();
}
