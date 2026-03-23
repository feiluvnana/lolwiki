import 'dart:convert';

import 'package:flncrawly/src/response/text_response.dart';
import 'package:jmespath/jmespath.dart';
import 'package:json_path/json_path.dart';

/// A response containing JSON content with JSONPath and JMESPath queries.
///
/// ### JSONPath
/// ```dart
/// res.$path(r'$.store.book[0].title')?.text()
/// res.$pathall(r'$.store.book[*].price').text()
/// ```
///
/// ### JMESPath
/// ```dart
/// res.$jmes('store.book[0]')?.raw()
/// res.$jmesall("store.book[?price < `10`].title").text()
/// ```
class JsonResponse extends TextResponse {
  JsonResponse({
    required super.url,
    required super.status,
    required super.headers,
    required super.body,
    required super.request,
    required super.meta,
  });

  /// The root JSON selector for this response.
  JsonSelector get selector => JsonSelector(jsonDecode(text));

  JsonSelector? $path(String selector) => this.selector.$path(selector);
  JsonSelectionList $pathall(String selector) => this.selector.$pathall(selector);
  JsonSelector? $jmes(String selector) => this.selector.$jmes(selector);
  JsonSelectionList $jmesall(String selector) => this.selector.$jmesall(selector);

  /// Raw decoded JSON data.
  dynamic data() => selector.raw();
}

/// Wraps a JSON value with query and extraction methods.
final class JsonSelector {
  final dynamic _value;
  const JsonSelector(this._value);

  JsonSelector? $path(String expr) {
    final match = JsonPath(expr).read(_value).firstOrNull;
    return match == null ? null : JsonSelector(match.value);
  }

  JsonSelectionList $pathall(String expr) => JsonSelectionList(
    JsonPath(expr).read(_value).map((m) => JsonSelector(m.value)).toList(),
  );

  JsonSelector? $jmes(String expr) {
    final result = search(expr, _value);
    return result == null ? null : JsonSelector(result);
  }

  JsonSelectionList $jmesall(String expr) {
    final result = search(expr, _value);
    if (result is List) {
      return JsonSelectionList(result.map((m) => JsonSelector(m)).toList());
    }
    return JsonSelectionList(result == null ? [] : [JsonSelector(result)]);
  }

  T map<T>(T Function(dynamic value) fn) => fn(_value);
  String text() => _value?.toString().trim() ?? '';
  dynamic raw() => _value;
}

/// A list of [JsonSelector]s with batch extraction and natural iteration.
///
/// ```dart
/// for (final node in res.$pathall(r'$.items[*]')) {
///   print(node.text());
/// }
/// res.$pathall(r'$.items[*]')[0].raw()
/// ```
final class JsonSelectionList extends Iterable<JsonSelector> {
  final List<JsonSelector> _items;
  const JsonSelectionList(this._items);

  @override
  Iterator<JsonSelector> get iterator => _items.iterator;

  JsonSelector operator [](int index) => _items[index];
  List<JsonSelector> get items => _items;

  List<String> text() => [for (final e in _items) e.text()];
  List<dynamic> raw() => [for (final e in _items) e.raw()];
}
