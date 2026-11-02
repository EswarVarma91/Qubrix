# SDK Training Guide — what the SDK can learn and what to send it

> Responsibility split (read first): the **main app owns files + sync**,
> the **SDK owns the model + learning + answering**.
> The model is chosen only by the SDK via Firebase Remote Config
> (`hf_model_url` → `SdkFirebaseOptions` / `SdkRemoteConfigService`).
> Hosts never pick the model. This guide covers only the Q&A side.

## 1. What kind of learning material helps

The SDK learns **Q&A pairs about your app** — what each screen/feature does
and how to do each task (e.g. how to book events, merchandise, packages,
activities). One pair = one way a user might ask + the approved answer **in
the same language**.

Accepted host sources (the host converts; the SDK never parses these):

| Host source | Example | Host converts to |
|---|---|---|
| Canonical JSON | `qa.json` (`QaTrainingBundle.toJson`) | send as-is to `ingestKnowledge` |
| Compact JSON | short keys `i,q,a,l,c,u,v` | `QaPair.fromJson` accepts both |
| XML | `<qa><q>..</q><a>..</a><lang>nl</lang></qa>` | host XML → `QaPair` list |
| CSV | `id,question,answer,lang,category,updatedAt,version` | host CSV → `QaPair` list |
| Markdown / DOC | FAQ doc, help-center export | host splits per heading → `QaPair` list |

Minimum per pair: `id`, `question`, `answer`, `lang` (BCP-47:
`en|hi|te|nl|fr|es|…`), `updatedAt`. Recommended: `category`
(`booking-events`, `merchandise`, `packages`, `activities`),
`version` (int, higher wins), optional `actionId` + `actionParameters`
to hint an already-registered SDK action (automation reuses the existing
`AutomationEngine` — no new engine was added).

What NOT to send: user identity, tokens, device ids, raw logs, PII.
Only Q&A. The server stores questions/answers to improve the product;
it must never store who asked them.

## 2. Canonical shapes (Dart surface the main app calls)

```dart
// Types: QaPair, QaTrainingBundle, IngestResult, KnowledgeAnswer,
// KnowledgeStats, KnowledgeAutomationHint (exported from qubrix.dart).

final bundle = QaTrainingBundle(
  appId: 'com.joyce.app',
  bundleVersion: '2026-11-02T09:00:00Z',
  pairs: [
    QaPair(
      id: 'booking-event-en-001',
      question: 'How do I book an event?',
      answer: 'Open Events > pick a date > Confirm booking.',
      lang: 'en',
      category: 'booking-events',
      updatedAt: DateTime.now().toUtc(),
      version: 1,
      actionId: 'book_event', // must already be registered
      actionParameters: {'type': 'event'},
    ),
  ],
  syncedUpTo: DateTime.now().toUtc(),
  source: 'server-merge',
);

final result = await engine.ingestKnowledge(bundle);
// result: {added, updated, skipped, errors, totalReceived}

// Incremental delta (only-new-items):
await engine.upsertQaPairs(newPairs);
await engine.removeQaPairs(['stale-id']);

// Ask (pass UI locale when known; else auto-detect te/hi/nl/fr/es/en):
final hit = await engine.askKnowledge('Hoe boek ik een evenement?', lang: 'nl');
// hit!.answer is Dutch, hit.lang == 'nl', hit.confidence 0..1.

engine.knowledgeStats(); // {totalPairs, perLang, perCategory, ...}
await engine.clearKnowledge(); // logout / reset only.
```

Storage shape on device: normalized `question|lang` index, hashed dedupe
(same question+lang under two ids collapses to the newer
`updatedAt`/`version`), compact short-key form (`i,q,a,l,c,u,v,aid,ap`),
LRU eviction oldest-`updatedAt`-first (default cap 5000 pairs) so app size
does not grow. Hosts may persist `exportKnowledgeCompact()` themselves.

## 3. Multilingual rule (Dutch, French, Spanish, Telugu, Hindi, English…)

- Teach **every language separately**: the same question in `en`, `hi`,
  `te`, `nl`, `fr`, `es` is 6 pairs with 6 answers, each answer written in
  its own language.
- `askKnowledge(question, lang: locale)` answers **only within that lang**:
  exact normalized match → confidence 1.0, else same-lang token-overlap
  (≥ 0.35), else `null` (means "not taught yet", not a wrong-language guess).
- Different mindsets ("how to booking events" vs "how do I book
  merchandise/package/activities") are just more pairs; the A→Z server merge
  (see `MAIN_APP_SYNC_COMPANION.md`) shares them to every device so each SDK
  eventually answers every phrasing.

## 4. Automation capability — is it in the SDK?

Yes, already: `ActionRegistry` + `AutomationEngine` (Suggest/Prepare/Execute)
with permissions and confirmation. Q&A adds only a **thin hint**:
`QaPair.actionId` → `engine.automationHintForQa(qaId)` → run via the existing
`engine.runAutomation(workflowId)` / registered action handler. If no hint or
action is registered, the SDK answers text-only. No model change.

## 5. Firebase config — where to change it

Model URL only: Firebase Console → Remote Config → `hf_model_url`
(`https://huggingface.co/<owner>/<repo>`). Code lives in
`dart/lib/src/firebase/sdk_firebase_options.dart`
(`SdkFirebaseOptions`, project `qubrix-77954`) — see
`dart/firebase_config_setup.md`. Q&A training never touches Firebase;
don't mix the two.

## 6. Host conversion examples

JSON (canonical) → send directly. XML/CSV/MD: parse host-side, e.g.
XML `<qa id lang category updatedAt version><q/><a/><actionId/></qa>` →
`QaPair(...)`; CSV row → `QaPair(...)`; Markdown `## How do I…` heading +
body → one `QaPair` per section with host-assigned `id`/`lang`/`updatedAt`.
Then `QaTrainingBundle(appId, bundleVersion, pairs)` → `ingestKnowledge`.
Full sync flow (upload only-new, `synced` flag, download merge) is in
`MAIN_APP_SYNC_COMPANION.md`.
