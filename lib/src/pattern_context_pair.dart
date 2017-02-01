part of xpath_dart;

class PatternContextPair<String,TokenContext> extends MapBase<String,TokenContext> {
  Map<String,TokenContext> _map = {};
  operator [](key) => _map[key];
  void operator []=(key, value) {
    _map[key] = value;
  }
  remove(key) => _map.remove(key);
  void clear() => _map.clear();
  Iterable get keys => _map.keys;
}
