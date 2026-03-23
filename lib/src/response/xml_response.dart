import 'package:flncrawly/src/response/text_response.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

/// A response containing XML content with XPath query capabilities.
///
/// ```dart
/// final title = res.$x('//title')?.text();
/// final items = res.$xall('//item/name').text();
/// final id = res.$x('//product')?.attr('id');
/// ```
class XmlResponse extends TextResponse {
  late final XmlDocument _doc = XmlDocument.parse(text);

  XmlResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  XmlSelector get selector => XmlSelector.document(_doc);
  XmlSelector? $x(String expression) => selector.$x(expression);
  XmlSelectionList $xall(String expression) => selector.$xall(expression);
}

/// Wraps an XML [XmlNode] with query and extraction methods.
class XmlSelector {
  final XmlNode _node;
  XmlSelector._(this._node);

  factory XmlSelector.document(XmlDocument document) => XmlSelector._(document);
  factory XmlSelector.node(XmlNode node) => XmlSelector._(node);

  XmlSelector? $x(String expression) {
    // ignore: experimental_member_use
    final match = _node.xpath(expression);
    return match.isEmpty ? null : XmlSelector.node(match.first);
  }

  XmlSelectionList $xall(String expression) => XmlSelectionList(
    // ignore: experimental_member_use
    _node.xpath(expression).map(XmlSelector.node).toList(),
  );

  T map<T>(T Function(XmlNode node) fn) => fn(_node);
  String text() => _node.innerText.trim();
  String xml() => _node.toXmlString();

  String attr(String name) {
    final node = _node;
    return node is XmlElement ? node.getAttribute(name)?.trim() ?? '' : '';
  }
}

/// A list of [XmlSelector]s with batch extraction and natural iteration.
///
/// ```dart
/// for (final node in res.$xall('//item')) {
///   print(node.text());
/// }
/// res.$xall('//item')[0].attr('id')
/// ```
final class XmlSelectionList extends Iterable<XmlSelector> {
  final List<XmlSelector> _items;
  const XmlSelectionList(this._items);

  @override
  Iterator<XmlSelector> get iterator => _items.iterator;

  XmlSelector operator [](int index) => _items[index];
  List<XmlSelector> get items => _items;

  List<String> text() => [for (final e in _items) e.text()];
  List<String> xml() => [for (final e in _items) e.xml()];
  List<String> attr(String name) => [for (final e in _items) e.attr(name)];
}
