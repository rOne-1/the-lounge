/// Runs [action] over [items] with at most [maxConcurrent] calls in flight
/// at once, instead of a plain sequential `for`-loop with `await` inside --
/// which turns what should be a handful of round trips into one full
/// network round trip per item (e.g. a 23-season show requiring 23
/// sequential TMDB calls before its season data resolves). Results are
/// returned in the same order as [items]; a failed [action] call propagates
/// the same way it would from a plain `await` in a loop.
Future<List<R>> mapBounded<T, R>(
  List<T> items,
  Future<R> Function(T item) action, {
  int maxConcurrent = 4,
}) async {
  if (items.isEmpty) return const [];
  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final i = nextIndex;
      if (i >= items.length) return;
      nextIndex++;
      results[i] = await action(items[i]);
    }
  }

  final workerCount = maxConcurrent < items.length ? maxConcurrent : items.length;
  await Future.wait(List.generate(workerCount, (_) => worker()));
  return results.cast<R>();
}
