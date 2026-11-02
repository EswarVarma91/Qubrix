/// Compact on-device knowledge index for host-supplied Q&A.
///
/// The main app owns sync (device -> server only-new `synced==false` items,
/// server -> device merged A-Z bundle). This store only ingests what the
/// host hands it via `ingestBundle` / `upsertPairs`, dedupes by
/// normalized-question + lang, evicts oldest-first, and answers in the query
/// language. No network, no Firebase, no model logic here.
library;

import 'knowledge_types.dart';

/// In-memory + serializable Q&A index. Hosts persist
/// `toCompactList()` themselves if they want disk caching.
class KnowledgeStore {
  /// Max pairs kept on device to bound app size. Oldest `updatedAt` evicted.
  final int maxPairs;

  final Map<String, QaPair> _byId = {};
  final Map<String, String> _keyToId = {};
  String? _bundleVersion;
  DateTime? _lastUpdatedAt;

  KnowledgeStore({this.maxPairs = 5000});

  /// Ingest a host-built bundle (server merge or converted host file).
  /// Incremental: newer `updatedAt` / higher `version` wins, else skipped.
  IngestResult ingestBundle(QaTrainingBundle bundle) {
    var added = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String>[];
    for (final pair in bundle.pairs) {
      try {
        final r = _upsertOne(pair);
        if (r == _Upsert.added) {
          added++;
        } else if (r == _Upsert.updated) {
          updated++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors.add('${pair.id}: $e');
        skipped++;
      }
    }
    _bundleVersion = bundle.bundleVersion;
    _touch();
    _evictIfNeeded();
    return IngestResult(
      totalReceived: bundle.pairs.length,
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Incremental upsert for server deltas / host-file deltas.
  IngestResult upsertPairs(List<QaPair> pairs) {
    var added = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String>[];
    for (final pair in pairs) {
      try {
        final r = _upsertOne(pair);
        if (r == _Upsert.added) {
          added++;
        } else if (r == _Upsert.updated) {
          updated++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors.add('${pair.id}: $e');
        skipped++;
      }
    }
    _touch();
    _evictIfNeeded();
    return IngestResult(
      totalReceived: pairs.length,
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Remove pairs by id (host-driven deletes / corrections).
  /// Returns number removed.
  int removeByIds(List<String> ids) {
    var removed = 0;
    for (final id in ids) {
      final existing = _byId.remove(id);
      if (existing != null) {
        removed++;
        if (_keyToId[existing.indexKey] == id) {
          _keyToId.remove(existing.indexKey);
        }
      }
    }
    return removed;
  }

  /// Answer directly from the local index, in the query language.
  ///
  /// 1. Exact normalized match in [lang] (or auto-detected).
  /// 2. Token-overlap fuzzy match within the same lang (threshold 0.35).
  /// 3. Otherwise null (no cross-language leakage: the host syncs every
  ///    language, so a missing lang means "not taught yet").
  KnowledgeAnswer? ask(String question, {String? lang}) {
    final qLang = (lang?.trim().toLowerCase().isEmpty ?? true)
        ? detectLanguage(question)
        : lang!.trim().toLowerCase();
    final norm = QaPair.normalizeQuestion(question);
    if (norm.isEmpty) return null;

    final key = '$norm|$qLang';
    final exactId = _keyToId[key];
    if (exactId != null) {
      final p = _byId[exactId];
      if (p != null) {
        return KnowledgeAnswer(
          answer: p.answer,
          lang: p.lang.trim().toLowerCase(),
          confidence: 1.0,
          sourceId: p.id,
          matchedQuestion: p.question,
        );
      }
    }

    // Fuzzy within the same language only, scored on content words.
    final qTokens = _tokens(norm);
    if (qTokens.isEmpty) return null;
    final qContent = _contentTokens(qLang, qTokens);
    QaPair? best;
    var bestScore = 0.0;
    for (final p in _byId.values) {
      if (p.lang.trim().toLowerCase() != qLang) continue;
      final pTokens = _tokens(QaPair.normalizeQuestion(p.question));
      final score =
          _overlap(qContent, _contentTokens(qLang, pTokens));
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
    if (best != null && bestScore >= 0.35) {
      return KnowledgeAnswer(
        answer: best.answer,
        lang: best.lang.trim().toLowerCase(),
        confidence: double.parse(bestScore.toStringAsFixed(2)),
        sourceId: best.id,
        matchedQuestion: best.question,
      );
    }
    return null;
  }

  KnowledgeStats stats() {
    final perLang = <String, int>{};
    final perCat = <String, int>{};
    for (final p in _byId.values) {
      final l = p.lang.trim().toLowerCase();
      perLang[l] = (perLang[l] ?? 0) + 1;
      final c = (p.category ?? 'general').trim().toLowerCase();
      perCat[c] = (perCat[c] ?? 0) + 1;
    }
    return KnowledgeStats(
      totalPairs: _byId.length,
      perLang: perLang,
      perCategory: perCat,
      lastUpdatedAt: _lastUpdatedAt,
      bundleVersion: _bundleVersion,
    );
  }

  /// Smallest wire/storage form: list of compact pair maps.
  List<Map<String, dynamic>> toCompactList() =>
      _byId.values.map((p) => p.toCompactJson()).toList();

  /// Restore from [toCompactList] output (or server compact payload).
  IngestResult restoreCompactList(
    List<Map<String, dynamic>> items, {
    String appId = 'host',
    String bundleVersion = 'restored',
  }) {
    final pairs = <QaPair>[];
    for (final item in items) {
      try {
        pairs.add(QaPair.fromJson(item));
      } catch (_) {
        // Skip a corrupt cached row instead of losing the whole cache.
      }
    }
    return ingestBundle(QaTrainingBundle(
      appId: appId,
      bundleVersion: bundleVersion,
      pairs: pairs,
      source: 'restore-compact',
    ));
  }

  void clear() {
    _byId.clear();
    _keyToId.clear();
    _bundleVersion = null;
    _lastUpdatedAt = null;
  }

  int get length => _byId.length;

  QaPair? getById(String id) => _byId[id];

  // --- internals ---

  _Upsert _upsertOne(QaPair pair) {
    if (pair.id.trim().isEmpty ||
        pair.question.trim().isEmpty ||
        pair.answer.trim().isEmpty) {
      throw ArgumentError('QaPair id/question/answer must be non-empty');
    }
    final existingById = _byId[pair.id];
    if (existingById != null) {
      if (!_isNewer(pair, existingById)) return _Upsert.skipped;
      if (existingById.indexKey != pair.indexKey) {
        _keyToId.remove(existingById.indexKey);
      }
      _byId[pair.id] = pair;
      _keyToId[pair.indexKey] = pair.id;
      return _Upsert.updated;
    }
    // Same question+lang under a different id: keep one canonical entry.
    final clashId = _keyToId[pair.indexKey];
    if (clashId != null) {
      final clash = _byId[clashId];
      if (clash != null && !_isNewer(pair, clash)) return _Upsert.skipped;
      if (clash != null) _byId.remove(clashId);
      _byId[pair.id] = pair;
      _keyToId[pair.indexKey] = pair.id;
      return clash == null ? _Upsert.added : _Upsert.updated;
    }
    _byId[pair.id] = pair;
    _keyToId[pair.indexKey] = pair.id;
    return _Upsert.added;
  }

  bool _isNewer(QaPair incoming, QaPair existing) {
    if (incoming.version != existing.version) {
      return incoming.version > existing.version;
    }
    // Strictly newer wins; identical re-uploads count as skipped so
    // only-new-items sync stays idempotent.
    return incoming.updatedAt.isAfter(existing.updatedAt);
  }

  void _evictIfNeeded() {
    if (_byId.length <= maxPairs) return;
    final sorted = _byId.values.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final overflow = _byId.length - maxPairs;
    for (var i = 0; i < overflow; i++) {
      final victim = sorted[i];
      _byId.remove(victim.id);
      if (_keyToId[victim.indexKey] == victim.id) {
        _keyToId.remove(victim.indexKey);
      }
    }
  }

  void _touch() {
    if (_byId.isEmpty) return;
    var latest = _byId.values.first.updatedAt;
    for (final p in _byId.values) {
      if (p.updatedAt.isAfter(latest)) latest = p.updatedAt;
    }
    _lastUpdatedAt = latest;
  }

  static Set<String> _tokens(String norm) => norm
      .split(RegExp(r'[^a-z0-9\u0900-\u097f\u0c00-\u0c7f\u00c0-\u024f]+'))
      .where((t) => t.isNotEmpty)
      .toSet();

  static double _overlap(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final inter = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0.0 : inter / union;
  }

  /// Function words per language so fuzzy matching keys on content words
  /// (e.g. `pakket` vs `evenement`) instead of `hoe/ik/een` overlap.
  static const Map<String, Set<String>> _stopwords = {
    'en': {
      'how', 'do', 'does', 'did', 'what', 'is', 'are', 'was', 'were',
      'the', 'a', 'an', 'to', 'of', 'in', 'on', 'for', 'and', 'or',
      'my', 'your', 'you', 'we', 'they', 'it', 'this', 'that', 'these',
      'those', 'with', 'from', 'please', 'me', 'i',
    },
    'nl': {
      'hoe', 'doe', 'doet', 'wat', 'is', 'zijn', 'de', 'het', 'een',
      'te', 'van', 'in', 'op', 'voor', 'en', 'of', 'mijn', 'je', 'jouw',
      'we', 'met', 'me', 'ik', 'dit', 'dat', 'deze', 'alstublieft',
    },
    'fr': {
      'comment', 'que', 'est', 'sont', 'le', 'la', 'les', 'un', 'une',
      'de', 'des', 'en', 'dans', 'sur', 'pour', 'et', 'ou', 'mon', 'ma',
      'mes', 'je', 'tu', 'vous', 'nous', 'avec', 'ce', 'cette', 'il',
    },
    'es': {
      'cómo', 'como', 'qué', 'que', 'es', 'son', 'el', 'la', 'los',
      'las', 'un', 'una', 'de', 'en', 'sobre', 'para', 'y', 'o', 'mi',
      'tu', 'su', 'con', 'esto', 'esta', 'por', 'favor',
    },
    'hi': {
      'kaise', 'kya', 'hai', 'hain', 'mein', 'ko', 'ka', 'ki', 'ke',
      'aur', 'main', 'mera', 'meri', 'aap', 'tum', 'karein', 'karo',
    },
    'te': const {},
  };

  static Set<String> _contentTokens(String lang, Set<String> tokens) {
    final stop = _stopwords[lang] ?? const <String>{};
    final content =
        tokens.where((t) => t.length > 2 && !stop.contains(t)).toSet();
    // Fall back to raw tokens when stemming leaves nothing (short queries).
    return content.isEmpty ? tokens : content;
  }

  /// Distinctive words per language used by [detectLanguage].
  /// Ambiguous words (e.g. `comment`) may appear in more than one set; they
  /// simply add a point to each, so a lone ambiguous word never decides.
  static const Map<String, Set<String>> _langMarkers = {
    'en': {
      'how', 'what', 'where', 'when', 'which', 'can', 'could', 'should',
      'book', 'booking', 'event', 'events', 'package', 'packages',
      'merchandise', 'activity', 'activities', 'comment', 'thanks',
      'please', 'my', 'i', 'do', 'does', 'the', 'is',
    },
    'nl': {
      'hoe', 'boek', 'boeken', 'geboekt', 'evenement', 'evenementen',
      'pakket', 'pakketten', 'activiteit', 'activiteiten', 'bedankt',
      'alstublieft', 'reserveren', 'gereserveerd', 'niet', 'mijn',
      'wil', 'kan', 'wat', 'waar',
    },
    'fr': {
      'comment', 'réserver', 'reserver', 'réservation', 'événement',
      'événements', 'evenement', 'forfait', 'forfaits', 'activité',
      'activités', 'merci', 'puis', 'veux', 'mon', 'ma', 'quel', 'quelle',
      'où', 'est',
    },
    'es': {
      'cómo', 'como', 'reservar', 'reserva', 'evento', 'eventos', 'paquete',
      'paquetes', 'actividad', 'actividades', 'gracias', 'mercancía',
      'mercancia', 'quiero', 'puedo', 'mi', 'dónde', 'donde', 'qué',
    },
    'hi': {
      'kaise', 'kya', 'karo', 'karein', 'dhanyavad', 'kripya', 'gatividhi',
      'chahiye', 'kaun', 'kahan', 'banaye', 'dekhe', 'milega',
    },
  };

  /// Tiny offline language guess. Hosts should pass an explicit `lang`
  /// whenever they know the UI locale; this is only the fallback.
  ///
  /// Script detection is exact for Telugu/Hindi. Latin-script text is scored
  /// by distinctive words per language, so an English "How do I book an
  /// event?" is not mistaken for Hindi just because it contains `book`.
  static String detectLanguage(String text) {
    if (RegExp(r'[\u0c00-\u0c7f]').hasMatch(text)) return 'te';
    if (RegExp(r'[\u0900-\u097f]').hasMatch(text)) return 'hi';

    final words = _tokens(text.toLowerCase());
    if (words.isEmpty) return 'en';

    var bestLang = 'en';
    var bestScore = words.intersection(_langMarkers['en']!).length;
    for (final entry in _langMarkers.entries) {
      if (entry.key == 'en') continue;
      final score = words.intersection(entry.value).length;
      if (score > bestScore) {
        bestScore = score;
        bestLang = entry.key;
      } else if (score == bestScore &&
          score >= 2 &&
          bestLang == 'en') {
        // Two distinctive hits in one non-English language beat shared
        // English-looking words (e.g. romanized Hindi "package kaise book
        // karein"). English stays the default on a single-word tie.
        bestLang = entry.key;
      }
    }
    return bestLang;
  }
}

enum _Upsert { added, updated, skipped }
