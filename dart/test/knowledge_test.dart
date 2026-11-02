import 'package:flutter_test/flutter_test.dart';
import 'package:qubrix/src/knowledge/knowledge_store.dart';
import 'package:qubrix/src/knowledge/knowledge_types.dart';

QaPair _pair(
  String id,
  String question,
  String answer, {
  String lang = 'en',
  String? category,
  DateTime? updatedAt,
  int version = 1,
  String? actionId,
}) {
  return QaPair(
    id: id,
    question: question,
    answer: answer,
    lang: lang,
    category: category,
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 2),
    version: version,
    actionId: actionId,
  );
}

QaTrainingBundle _bundle(List<QaPair> pairs, {String version = 'v1'}) {
  return QaTrainingBundle(
    appId: 'com.joyce.app',
    bundleVersion: version,
    pairs: pairs,
  );
}

void main() {
  group('KnowledgeStore ingestion', () {
    test('ingests a bundle and counts per language', () {
      final store = KnowledgeStore();
      final result = store.ingestBundle(_bundle([
        _pair('e1', 'How do I book an event?', 'Open Events.',
            category: 'booking-events'),
        _pair('n1', 'Hoe boek ik een evenement?', 'Open Evenementen.',
            lang: 'nl', category: 'booking-events'),
        _pair('h1', 'Package kaise book karein?', 'Package chunein.',
            lang: 'hi', category: 'packages'),
      ]));

      expect(result.totalReceived, 3);
      expect(result.added, 3);
      expect(result.skipped, 0);
      expect(result.ok, isTrue);

      final stats = store.stats();
      expect(stats.totalPairs, 3);
      expect(stats.perLang, {'en': 1, 'nl': 1, 'hi': 1});
      expect(stats.perCategory['booking-events'], 2);
      expect(stats.bundleVersion, 'v1');
    });

    test('re-ingesting identical pairs is idempotent (skipped)', () {
      final store = KnowledgeStore();
      final pair = _pair('e1', 'How do I book an event?', 'Open Events.');
      store.ingestBundle(_bundle([pair]));
      final again = store.upsertPairs([pair]);

      expect(again.added, 0);
      expect(again.updated, 0);
      expect(again.skipped, 1);
      expect(store.length, 1);
    });

    test('higher version wins, lower version is ignored', () {
      final store = KnowledgeStore();
      store.upsertPairs([_pair('e1', 'How do I book?', 'Old answer.')]);
      store.upsertPairs(
          [_pair('e1', 'How do I book?', 'New answer.', version: 2)]);
      store.upsertPairs(
          [_pair('e1', 'How do I book?', 'Stale answer.', version: 1)]);

      expect(store.getById('e1')!.answer, 'New answer.');
      expect(store.getById('e1')!.version, 2);
    });

    test('same question+lang under a different id collapses to one entry', () {
      final store = KnowledgeStore();
      store.upsertPairs([_pair('a', 'How do I pay?', 'Card.')]);
      store.upsertPairs([
        _pair('b', 'how do   i PAY?', 'Card or cash.',
            updatedAt: DateTime.utc(2026, 11, 3))
      ]);

      expect(store.length, 1);
      expect(store.getById('b')!.answer, 'Card or cash.');
      expect(store.getById('a'), isNull);
    });

    test('removes pairs by id', () {
      final store = KnowledgeStore();
      store.upsertPairs([
        _pair('a', 'How do I pay?', 'Card.'),
        _pair('b', 'Where is my order?', 'Orders screen.'),
      ]);

      expect(store.removeByIds(['a', 'missing']), 1);
      expect(store.length, 1);
      expect(store.getById('b'), isNotNull);
    });

    test('evicts oldest pairs beyond maxPairs', () {
      final store = KnowledgeStore(maxPairs: 2);
      store.upsertPairs([
        _pair('old', 'How do I pay?', 'Card.',
            updatedAt: DateTime.utc(2026, 1, 1)),
        _pair('mid', 'Where is my order?', 'Orders.',
            updatedAt: DateTime.utc(2026, 2, 1)),
        _pair('new', 'How do I return?', 'Returns.',
            updatedAt: DateTime.utc(2026, 3, 1)),
      ]);

      expect(store.length, 2);
      expect(store.getById('old'), isNull);
      expect(store.getById('new'), isNotNull);
    });

    test('reports a malformed pair instead of throwing', () {
      final store = KnowledgeStore();
      final result = store.upsertPairs([
        QaPair(
            id: '  ',
            question: 'q',
            answer: 'a',
            updatedAt: DateTime.utc(2026)),
      ]);
      expect(result.errors, isNotEmpty);
      expect(result.skipped, 1);
    });
  });

  group('KnowledgeStore answering', () {
    late KnowledgeStore store;

    setUp(() {
      store = KnowledgeStore();
      store.ingestBundle(_bundle([
        _pair('e1', 'How do I book an event?', 'Open Events > pick a date.'),
        _pair('e2', 'How do I book merchandise?', 'Open Shop > checkout.'),
        _pair('n1', 'Hoe boek ik een evenement?', 'Open Evenementen.',
            lang: 'nl'),
        _pair('h1', 'Package kaise book karein?', 'Package chunein.',
            lang: 'hi'),
        _pair('t1', 'ఈవెంట్ ఎలా బుక్ చేయాలి?', 'ఈవెంట్స్ తెరవండి.',
            lang: 'te'),
      ]));
    });

    test('exact match ignores case and extra spaces', () {
      final hit = store.ask('how do I  book an EVENT?', lang: 'en');
      expect(hit, isNotNull);
      expect(hit!.sourceId, 'e1');
      expect(hit.lang, 'en');
      expect(hit.confidence, 1.0);
      expect(hit.answer, 'Open Events > pick a date.');
    });

    test('answers in the requested language, never cross-language', () {
      final nl = store.ask('Hoe boek ik een evenement?', lang: 'nl');
      expect(nl!.lang, 'nl');
      expect(nl.answer, 'Open Evenementen.');

      // Dutch question that was never taught in Dutch -> no English answer.
      expect(store.ask('Waar is mijn pakket?', lang: 'nl'), isNull);
    });

    test('fuzzy match works on content words', () {
      final hit = store.ask('How can I book merchandise?', lang: 'en');
      expect(hit, isNotNull);
      expect(hit!.sourceId, 'e2');
      expect(hit.confidence, greaterThanOrEqualTo(0.35));
    });

    test('unrelated question returns null', () {
      expect(store.ask('what is the weather', lang: 'en'), isNull);
    });

    test('empty question returns null', () {
      expect(store.ask('   ', lang: 'en'), isNull);
    });
  });

  group('Language detection', () {
    test('English questions containing "book" stay English', () {
      expect(KnowledgeStore.detectLanguage('How do I book an event?'), 'en');
    });

    test('detects Dutch', () {
      expect(KnowledgeStore.detectLanguage('Hoe boek ik een evenement?'), 'nl');
    });

    test('detects romanized Hindi by its distinctive words', () {
      expect(KnowledgeStore.detectLanguage('Package kaise book karein?'), 'hi');
    });

    test('detects scripts directly', () {
      expect(KnowledgeStore.detectLanguage('ఈవెంట్ ఎలా బుక్ చేయాలి?'), 'te');
      expect(KnowledgeStore.detectLanguage('पैकेज कैसे बुक करें?'), 'hi');
    });

    test('auto-detection works when lang is omitted', () {
      final store = KnowledgeStore();
      store.upsertPairs([
        _pair('n1', 'Hoe boek ik een evenement?', 'Open Evenementen.',
            lang: 'nl'),
      ]);
      final hit = store.ask('Hoe boek ik een evenement?');
      expect(hit, isNotNull);
      expect(hit!.lang, 'nl');
    });
  });

  group('Compact storage', () {
    test('compact list round-trips into a fresh store', () {
      final store = KnowledgeStore();
      store.upsertPairs([
        _pair('e1', 'How do I book an event?', 'Open Events.',
            category: 'booking-events', actionId: 'book_event'),
        _pair('n1', 'Hoe boek ik een evenement?', 'Open Evenementen.',
            lang: 'nl'),
      ]);

      final compact = store.toCompactList();
      expect(compact.first.keys, containsAll(['i', 'q', 'a', 'l', 'u', 'v']));

      final restored = KnowledgeStore();
      final result = restored.restoreCompactList(compact);
      expect(result.added, 2);
      expect(restored.ask('How do I book an event?', lang: 'en'), isNotNull);
      expect(restored.getById('e1')!.actionId, 'book_event');
    });

    test('compact bundle JSON round-trips', () {
      final bundle = _bundle([
        _pair('e1', 'How do I book an event?', 'Open Events.',
            category: 'booking-events'),
      ]);
      final decoded = QaTrainingBundle.fromJson(bundle.toCompactJson());

      expect(decoded.appId, 'com.joyce.app');
      expect(decoded.bundleVersion, 'v1');
      expect(decoded.pairs.single.question, 'How do I book an event?');
      expect(decoded.pairs.single.category, 'booking-events');
    });

    test('malformed rows are skipped without dropping good ones', () {
      final decoded = QaTrainingBundle.fromJson({
        'app': 'com.joyce.app',
        'bv': 'v2',
        'p': [
          {'i': 'ok', 'q': 'How do I pay?', 'a': 'Card.', 'l': 'en'},
          {'i': 'bad'}, // missing question/answer
          'not-a-map',
        ],
      });

      expect(decoded.pairs.length, 1);
      expect(decoded.pairs.single.id, 'ok');
    });

    test('accepts numeric and string versions from JSON', () {
      expect(QaPair.fromJson({'i': 'a', 'q': 'q', 'a': 'a', 'v': 3}).version, 3);
      expect(QaPair.fromJson({'i': 'a', 'q': 'q', 'a': 'a', 'v': '4'}).version, 4);
      expect(QaPair.fromJson({'i': 'a', 'q': 'q', 'a': 'a'}).version, 1);
    });
  });

  group('Clear', () {
    test('clear drops every pair and stats', () {
      final store = KnowledgeStore();
      store.upsertPairs([_pair('e1', 'How do I pay?', 'Card.')]);
      store.clear();

      expect(store.length, 0);
      expect(store.stats().totalPairs, 0);
      expect(store.ask('How do I pay?', lang: 'en'), isNull);
    });
  });
}
