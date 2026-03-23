import 'package:flncrawly/src/response/text_response.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// A response containing HTML content with CSS and XPath query capabilities.
///
/// ### CSS Selectors
/// ```dart
/// final title = res.$('h1')?.text();
/// final links = res.$all('a').attr('href');
/// final price = res.$('.product')?.$('.price')?.text();
/// ```
///
/// ### XPath Selectors
/// ```dart
/// final node = res.$x('//div[@class="content"]');
/// final items = res.$xall('//li/a').text();
/// ```
///
/// ### Absolute URLs
/// ```dart
/// final url = res.$('a')?.absurl('href');
/// // 'page/2' → 'https://example.com/page/2'
/// ```
class HtmlResponse extends TextResponse {
  late final Document _doc = parse(text);

  HtmlResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// Root selector, with [url] as base for resolving relative links.
  HtmlSelector get selector {
    final root = _doc.documentElement;
    if (root == null) throw StateError('No documentElement.');
    return HtmlSelector._(root, url);
  }

  HtmlSelector? $(String selector) => this.selector.$(selector);
  HtmlSelectionList $all(String selector) => this.selector.$all(selector);
  HtmlSelector? $x(String expression) => selector.$x(expression);
  HtmlSelectionList $xall(String expression) => selector.$xall(expression);
}

/// Wraps an HTML [Element] with query and extraction methods.
///
/// ```dart
/// final node = res.$('.product');
/// node?.text()              // trimmed text content
/// node?.attr('id')          // attribute value
/// node?.absurl('href')      // resolved absolute URL
/// node?.$('span')?.text()   // nested query
/// ```
class HtmlSelector {
  final Element _element;
  final HtmlXPath _xpath;
  final Uri? _baseUrl;

  HtmlSelector._(this._element, [this._baseUrl])
    : _xpath = HtmlXPath.node(_element);

  HtmlSelector? $(String selector) {
    final el = _element.querySelector(selector);
    return el == null ? null : HtmlSelector._(el, _baseUrl);
  }

  HtmlSelectionList $all(String selector) => HtmlSelectionList(
    _element
        .querySelectorAll(selector)
        .map((e) => HtmlSelector._(e, _baseUrl))
        .toList(),
  );

  HtmlSelector? $x(String expression) {
    final node = _xpath.query(expression).node?.node;
    return node is Element ? HtmlSelector._(node, _baseUrl) : null;
  }

  HtmlSelectionList $xall(String expression) => HtmlSelectionList(
    _xpath
        .query(expression)
        .nodes
        .map((m) => m.node)
        .whereType<Element>()
        .map((e) => HtmlSelector._(e, _baseUrl))
        .toList(),
  );

  /// Transform the current element using [fn].
  T map<T>(T Function(Element element) fn) => fn(_element);

  /// Trimmed text content.
  String text() => _element.text.trim();

  /// Attribute value, or empty string if absent.
  String attr(String name) => (_element.attributes[name] ?? '').trim();

  /// Resolves an attribute value as an absolute URL against the
  /// response's base URL.
  ///
  /// ```dart
  /// // res.url = 'https://example.com/books/'
  /// node.absurl('href')  // 'page2' → 'https://example.com/books/page2'
  /// node.absurl('src')   // '/img/a.png' → 'https://example.com/img/a.png'
  /// ```
  ///
  /// Returns `null` if the attribute is absent or empty.
  String? absurl(String name) {
    final val = _element.attributes[name]?.trim();
    if (val == null || val.isEmpty) return null;
    final base = _baseUrl;
    if (base != null) return base.resolve(val).toString();
    return val;
  }

  /// Inner HTML.
  String inner() => _element.innerHtml;

  /// Outer HTML.
  String outer() => _element.outerHtml;

  /// Tag name.
  String tag() => _element.localName ?? '';
}

/// A list of [HtmlSelector]s with batch extraction and natural iteration.
///
/// ```dart
/// for (final node in res.$all('.product')) {
///   print(node.text());
///   print(node.absurl('href'));
/// }
/// res.$all('.product')[0].$('a')?.text()
/// ```
final class HtmlSelectionList extends Iterable<HtmlSelector> {
  final List<HtmlSelector> _items;
  const HtmlSelectionList(this._items);

  @override
  Iterator<HtmlSelector> get iterator => _items.iterator;

  HtmlSelector operator [](int index) => _items[index];
  List<HtmlSelector> get items => _items;

  List<String> text() => [for (final e in _items) e.text()];
  List<String> attr(String name) => [for (final e in _items) e.attr(name)];

  /// Resolve an attribute as absolute URLs for all elements.
  List<String?> absurl(String name) => [for (final e in _items) e.absurl(name)];

  List<String> inner() => [for (final e in _items) e.inner()];
  List<String> outer() => [for (final e in _items) e.outer()];
}
