import 'dart:convert';
import 'package:flncrawly/src/response/response.dart';
import 'package:jmespath/jmespath.dart';
import 'package:json_path/json_path.dart';

class JsonResponse extends TextResponse {
  const JsonResponse({
    required super.url,
    required super.status,
    required super.body,
    super.headers,
    required super.request,
    super.meta,
  });

  JsonSelector get selector => JsonSelector._(jsonDecode(text), []);
  JsonSelector $path(String expr) => selector.$path(expr);
  JsonSelector $jmes(String expr) => selector.$jmes(expr);
  JsonSelection? one() => selector.one();
  JsonSelections all() => selector.all();
}

enum JsonSelectorType { path, jmes }

class JsonSelector {
  final dynamic data;

  final List<(JsonSelectorType type, String expr)> selectors;

  const JsonSelector._(this.data, this.selectors);

  JsonSelector $path(String expr) {
    return JsonSelector._(data, selectors + [(JsonSelectorType.path, expr)]);
  }

  JsonSelector $jmes(String expr) {
    return JsonSelector._(data, selectors + [(JsonSelectorType.jmes, expr)]);
  }

  JsonSelection? one() {
    dynamic current = data;
    for (final (type, expr) in selectors) {
      switch (type) {
        case JsonSelectorType.path:
          final match = JsonPath(expr).read(current).firstOrNull;
          if (match == null) return null;
          current = match.value;
        case JsonSelectorType.jmes:
          final result = search(expr, current);
          if (result == null) return null;
          current = result;
      }
    }
    return JsonSelection._(current);
  }

  JsonSelections all() {
    Iterable<dynamic> current = [data];
    for (final (type, expr) in selectors) {
      switch (type) {
        case JsonSelectorType.path:
          current = current.expand((c) => JsonPath(expr).read(c).map((m) => m.value));
        case JsonSelectorType.jmes:
          current = current.expand((c) {
            final result = search(expr, c);
            if (result is List) return result;
            return result == null ? [] : [result];
          });
      }
    }
    return JsonSelections._(current.toList());
  }
}

final class JsonSelection {
  final dynamic value;

  const JsonSelection._(this.value);

  JsonSelector $path(String expr) => JsonSelector._(value, [(JsonSelectorType.path, expr)]);
  JsonSelector $jmes(String expr) => JsonSelector._(value, [(JsonSelectorType.jmes, expr)]);

  String text() => value?.toString().trim() ?? '';
  dynamic raw() => value;
}

final class JsonSelections extends Iterable<JsonSelection> {
  final List<dynamic> values;

  const JsonSelections._(this.values);

  @override
  Iterator<JsonSelection> get iterator => values.map((v) => JsonSelection._(v)).iterator;

  Iterable<JsonSelector> $(String expr) => values.map((v) => JsonSelector._(v, [(JsonSelectorType.path, expr)]));
  Iterable<JsonSelector> $jmes(String expr) => values.map((v) => JsonSelector._(v, [(JsonSelectorType.jmes, expr)]));

  List<String> text() => map((e) => e.text()).toList();
  List<dynamic> raw() => map((e) => e.raw()).toList();
}
