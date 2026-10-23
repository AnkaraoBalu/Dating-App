import 'home_discover_data.dart';

/// Keep queued cards in place and append unseen cards from the next response.
/// Dismissals are checked at response time because swipes may still be saving.
List<HomePerson> mergeDiscoveryFeed({
  required List<HomePerson> current,
  required List<HomePerson> incoming,
  required Set<String> dismissedIds,
}) {
  final seen = <String>{};
  return [...current, ...incoming]
      .where(
        (person) => !dismissedIds.contains(person.id) && seen.add(person.id),
      )
      .toList();
}

/// Null means the next step is allowing profiles beyond the distance limit.
int? nextDiscoveryRadius(int radiusKm) {
  for (final radius in [25, 50, 100]) {
    if (radius > radiusKm) return radius;
  }
  return null;
}

/// Restore a failed swipe without replacing the rest of the queue.
List<HomePerson> restoreDiscoveryCard(
  List<HomePerson> current,
  HomePerson person,
  int index,
) {
  if (current.any((card) => card.id == person.id)) return current;
  final restored = [...current];
  restored.insert(index.clamp(0, restored.length), person);
  return restored;
}
