import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/mood_catalog_item.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Live mood catalogue (emoji / label / message) fetched from GET /api/v1/moods.
///
/// The mood emojis, labels, and post-check-in messages are admin-managed and
/// must reflect edits made in the Filament panel. The screens used to hardcode
/// them, so admin changes never showed. This singleton fetches the catalogue,
/// caches it (secure storage, for instant first paint), and refreshes from the
/// network so changes propagate. Colours/layout stay local (keyed by slug), so
/// rendering is unchanged — only the dynamic content is sourced here.
///
/// Lookups return null when the catalogue hasn't loaded a given slug yet; the
/// screens fall back to their bundled defaults in that case, so the UI is never
/// empty.
class MoodCatalog {
  MoodCatalog._();
  static final MoodCatalog instance = MoodCatalog._();

  static const String _storageKey = 'mishkat.mood_catalog.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Map<String, MoodCatalogItem> _bySlug = <String, MoodCatalogItem>{};
  bool _hydratedFromCache = false;
  Future<void>? _inFlight;

  /// Active mood slugs in catalogue (display) order. Empty until loaded — the
  /// screens fall back to their bundled order in that case.
  List<String> get orderedSlugs => _bySlug.keys.toList(growable: false);

  String? colorSeedFor(String slug) {
    final String? seed = _bySlug[slug]?.colorSeed;
    return (seed != null && seed.trim().isNotEmpty) ? seed : null;
  }

  String? emojiFor(String slug) => _bySlug[slug]?.emoji;

  String? labelFor(String slug) {
    final String? name = _bySlug[slug]?.nameAr;
    return (name != null && name.trim().isNotEmpty) ? name : null;
  }

  String? messageFor(String slug) {
    final String? msg = _bySlug[slug]?.messageAr;
    return (msg != null && msg.trim().isNotEmpty) ? msg : null;
  }

  /// Load cached values first (instant), then refresh from the network. Safe to
  /// call on every screen open — the network call collapses concurrent calls.
  Future<void> ensureLoaded() async {
    if (!_hydratedFromCache) {
      await _hydrateFromCache();
    }
    await refresh();
  }

  Future<void> refresh() {
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  void clear() {
    _bySlug = <String, MoodCatalogItem>{};
  }

  Future<void> _fetch() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.moods);
      final Map<String, MoodCatalogItem>? parsed = _parse(data);
      if (parsed != null && parsed.isNotEmpty) {
        _bySlug = parsed;
        unawaited(_persist(parsed));
      }
    } catch (_) {
      // Offline / error — keep whatever we have (cache or empty); screens fall
      // back to their bundled defaults.
    }
  }

  Future<void> _hydrateFromCache() async {
    _hydratedFromCache = true;
    try {
      final String? raw = await _storage.read(key: _storageKey);
      if (raw == null) return;
      final Map<String, MoodCatalogItem>? parsed = _parse(jsonDecode(raw));
      if (parsed != null && parsed.isNotEmpty) _bySlug = parsed;
    } catch (_) {
      // ignore corrupt cache
    }
  }

  Future<void> _persist(Map<String, MoodCatalogItem> map) async {
    try {
      final List<Map<String, dynamic>> json =
          map.values.map((MoodCatalogItem e) => e.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(json));
    } catch (_) {
      // best-effort
    }
  }

  Map<String, MoodCatalogItem>? _parse(dynamic data) {
    final List<dynamic>? list = moodListFromResponse(data);
    if (list == null) return null;
    final Map<String, MoodCatalogItem> map = <String, MoodCatalogItem>{};
    for (final dynamic raw in list) {
      if (raw is Map<String, dynamic>) {
        final MoodCatalogItem item = MoodCatalogItem.fromJson(raw);
        if (item.slug.isNotEmpty) map[item.slug] = item;
      }
    }
    return map;
  }

  /// The /moods envelope is `{data: {moods: [...]}}`, so ApiClient hands us
  /// `{moods: [...]}` (a Map) — not a bare list. Accept both shapes (and the
  /// cached bare-list form). Returns null if neither matches.
  static List<dynamic>? moodListFromResponse(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['moods'] is List) {
      return data['moods'] as List<dynamic>;
    }
    return null;
  }
}
