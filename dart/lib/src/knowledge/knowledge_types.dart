/// Knowledge training payload types for the Qubrix SDK.
///
/// The host (main) app owns every file and every sync. The SDK only receives
/// a normalized [QaTrainingBundle] and learns it into a compact on-device
/// index. Model selection stays with the SDK (Firebase Remote Config
/// `hf_model_url`) and is intentionally untouched by this file.
library;

/// A single question/answer pair the host app teaches the SDK.
///
/// Only Q&A travels to the server / SDK. Never put user identity, tokens,
/// device ids, or raw event logs in here.
class QaPair {
  /// Stable id, e.g. `booking-event-en-001`. If two pairs share an id the
  /// newer `updatedAt` (or higher `version`) wins during ingestion.
  final String id;

  /// The question as a user would ask it.
  final String question;

  /// The approved answer in the same language as [lang].
  final String answer;

  /// BCP-47 language tag: `en`, `hi`, `te`, `nl`, `fr`, `es`, ...
  final String lang;

  /// Optional grouping, e.g. `booking-events`, `merchandise`, `packages`.
  final String? category;

  /// When this pair was last edited on the host/server side.
  final DateTime updatedAt;

  /// Monotonic version for conflict resolution. Higher wins.
  final int version;

  /// Optional thin automation hint: which registered SDK action this answer
  /// maps to (e.g. `book_event` with `{"type":"event"}`). The SDK reuses the
  /// existing `AutomationEngine` / `ActionRegistry` — no new engine.
  final String? actionId;

  /// Parameters replayed when the hinted action runs.
  final Map<String, dynamic>? actionParameters;

  const QaPair({
    required this.id,
    required this.question,
    required this.answer,
    this.lang = 'en',
    this.category,
    required this.updatedAt,
    this.version = 1,
    this.actionId,
    this.actionParameters,
  });

  /// Normalized question used for dedupe + matching.
  static String normalizeQuestion(String q) {
    return q.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Dedupe key: normalized question + lowercased lang.
  String get indexKey =>
      '${normalizeQuestion(question)}|${lang.trim().toLowerCase()}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'lang': lang,
        'category': category,
        'updatedAt': updatedAt.toIso8601String(),
        'version': version,
        if (actionId != null) 'actionId': actionId,
        if (actionParameters != null) 'actionParameters': actionParameters,
      };

  /// Compact on-device / on-wire form (short keys, skips nulls).
  /// `i,q,a,l,c,u,v,aid,ap` — keeps device storage small.
  Map<String, dynamic> toCompactJson() => {
        'i': id,
        'q': question,
        'a': answer,
        'l': lang,
        if (category != null) 'c': category,
        'u': updatedAt.millisecondsSinceEpoch,
        'v': version,
        if (actionId != null) 'aid': actionId,
        if (actionParameters != null) 'ap': actionParameters,
      };

  factory QaPair.fromJson(Map<String, dynamic> json) {
    // Accept both full and compact keys so hosts can send either.
    final id = _text(json['id'] ?? json['i']);
    final question = _text(json['question'] ?? json['q']);
    final answer = _text(json['answer'] ?? json['a']);
    if (id == null || question == null || answer == null) {
      throw const FormatException('QaPair needs non-empty id, question, answer');
    }

    final lang = _text(json['lang'] ?? json['l'])?.toLowerCase();

    DateTime updatedAt;
    final rawUpdated = json['updatedAt'] ?? json['u'];
    if (rawUpdated is num) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdated.toInt());
    } else {
      updatedAt = DateTime.tryParse(rawUpdated?.toString() ?? '') ??
          DateTime.now().toUtc();
    }

    // Be tolerant of `1`, `1.0` and `"1"` from JSON/servers.
    final rawVersion = json['version'] ?? json['v'];
    final version = rawVersion is num
        ? rawVersion.toInt()
        : int.tryParse(rawVersion?.toString() ?? '') ?? 1;

    final rawParams = json['actionParameters'] ?? json['ap'];
    Map<String, dynamic>? actionParameters;
    if (rawParams is Map) {
      actionParameters = rawParams.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return QaPair(
      id: id,
      question: question,
      answer: answer,
      lang: (lang == null || lang.isEmpty) ? 'en' : lang,
      category: _text(json['category'] ?? json['c']),
      updatedAt: updatedAt,
      version: version,
      actionId: _text(json['actionId'] ?? json['aid']),
      actionParameters: actionParameters,
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// A batch the host hands to `ingestKnowledge`.
///
/// Built by the host from any source file (JSON/XML/CSV/MD/DOC) or from the
/// server-merged A–Z download. The SDK never parses host files directly.
class QaTrainingBundle {
  /// Host app id, e.g. `com.whatsapp`, `com.joyce.app`.
  final String appId;

  /// Host/server bundle version, e.g. `2026-11-02T09:00:00Z` or build number.
  final String bundleVersion;

  /// Q&A pairs only — no user data.
  final List<QaPair> pairs;

  /// Server watermark the bundle is synced up to (for `synced` tracking).
  final DateTime? syncedUpTo;

  /// Where this bundle came from: `server-merge`, `host-json`, `host-xml`, ...
  final String? source;

  const QaTrainingBundle({
    required this.appId,
    required this.bundleVersion,
    required this.pairs,
    this.syncedUpTo,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'bundleVersion': bundleVersion,
        'pairs': pairs.map((p) => p.toJson()).toList(),
        if (syncedUpTo != null)
          'syncedUpTo': syncedUpTo!.toIso8601String(),
        if (source != null) 'source': source,
      };

  /// Compact form for small on-device storage / small sync payloads.
  Map<String, dynamic> toCompactJson() => {
        'app': appId,
        'bv': bundleVersion,
        'p': pairs.map((p) => p.toCompactJson()).toList(),
        if (syncedUpTo != null)
          'su': syncedUpTo!.millisecondsSinceEpoch,
        if (source != null) 's': source,
      };

  factory QaTrainingBundle.fromJson(Map<String, dynamic> json) {
    final rawPairs = json['pairs'] ?? json['p'];
    final pairs = <QaPair>[];
    if (rawPairs is List) {
      for (final entry in rawPairs) {
        try {
          if (entry is Map) {
            pairs.add(QaPair.fromJson(entry.cast<String, dynamic>()));
          }
        } catch (_) {
          // One malformed row must not block a whole sync/download.
        }
      }
    }

    DateTime? syncedUpTo;
    final rawSu = json['syncedUpTo'] ?? json['su'];
    if (rawSu is num) {
      syncedUpTo = DateTime.fromMillisecondsSinceEpoch(rawSu.toInt());
    } else if (rawSu != null) {
      syncedUpTo = DateTime.tryParse(rawSu.toString());
    }

    return QaTrainingBundle(
      appId: QaPair._text(json['appId'] ?? json['app']) ?? 'host',
      bundleVersion:
          QaPair._text(json['bundleVersion'] ?? json['bv']) ?? '1',
      pairs: pairs,
      syncedUpTo: syncedUpTo,
      source: QaPair._text(json['source'] ?? json['s']),
    );
  }
}

/// Result of an ingest / upsert call.
class IngestResult {
  final int totalReceived;
  final int added;
  final int updated;
  final int skipped;
  final List<String> errors;

  const IngestResult({
    required this.totalReceived,
    required this.added,
    required this.updated,
    required this.skipped,
    this.errors = const [],
  });

  bool get ok => errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'totalReceived': totalReceived,
        'added': added,
        'updated': updated,
        'skipped': skipped,
        'errors': errors,
      };
}

/// Answer returned by `askKnowledge`, always in the query language.
class KnowledgeAnswer {
  final String answer;
  final String lang;
  final double confidence;
  final String sourceId;
  final String? matchedQuestion;

  const KnowledgeAnswer({
    required this.answer,
    required this.lang,
    required this.confidence,
    required this.sourceId,
    this.matchedQuestion,
  });

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'lang': lang,
        'confidence': confidence,
        'sourceId': sourceId,
        if (matchedQuestion != null) 'matchedQuestion': matchedQuestion,
      };
}

/// Counts for debugging / dashboards.
class KnowledgeStats {
  final int totalPairs;
  final Map<String, int> perLang;
  final Map<String, int> perCategory;
  final DateTime? lastUpdatedAt;
  final String? bundleVersion;

  const KnowledgeStats({
    required this.totalPairs,
    required this.perLang,
    required this.perCategory,
    this.lastUpdatedAt,
    this.bundleVersion,
  });

  Map<String, dynamic> toJson() => {
        'totalPairs': totalPairs,
        'perLang': perLang,
        'perCategory': perCategory,
        if (lastUpdatedAt != null)
          'lastUpdatedAt': lastUpdatedAt!.toIso8601String(),
        if (bundleVersion != null) 'bundleVersion': bundleVersion,
      };
}

/// Thin automation hint carried by a [QaPair].
///
/// Resolved against the existing `ActionRegistry`; the SDK does not gain a
/// new automation engine for Q&A.
class KnowledgeAutomationHint {
  final String qaId;
  final String actionId;
  final Map<String, dynamic> parameters;
  final double confidence;

  const KnowledgeAutomationHint({
    required this.qaId,
    required this.actionId,
    required this.parameters,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'qaId': qaId,
        'actionId': actionId,
        'parameters': parameters,
        'confidence': confidence,
      };
}
