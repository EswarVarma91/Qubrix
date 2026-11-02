# Main-App Sync Companion — what the host app must do (SDK does none of this)

> The SDK never syncs. WhatsApp / Joyce / any host app owns **all** of this:
> local capture, `synced` flags, upload, server merge, download, scheduling,
> file parsing. The SDK only exposes `ingestKnowledge / upsertQaPairs /
> removeQaPairs / askKnowledge`. Model choice stays SDK-side via Firebase
> Remote Config `hf_model_url` (see `dart/firebase_config_setup.md`).

## 1. What the app must send UP (device → server)

- **Only Q&A, never user data.** Each record: `id, question, answer, lang,
  category?, updatedAt, version, synced=false` when first captured.
  No user id, no tokens, no device id, no raw logs.
- **Only-new-items:** `SELECT * WHERE synced == false`. Example: user A asks
  10 new questions → upload those 10, then mark them `synced=true` only after
  server ACK. User B later asks 100 (10 overlap + 90 new) → upload only the
  90 unsynced. Never re-upload `synced=true`.
- Payload: canonical `QaTrainingBundle.toJson()` or compact
  `toCompactJson()` (`app, bv, p[], su`). Small format keeps it fast.
- Example (pseudo-Dart, host-side store):
  ```dart
  final unsynced = await localQa.where((e) => !e.synced).toList();
  if (unsynced.isEmpty) return;
  await api.post('/v1/qa:upload', body: {
    'appId': 'com.joyce.app',
    'deviceBundle': '2026-11-02T09:00:00Z',
    'pairs': unsynced.map((e) => e.toJson()).toList(), // Q&A only
  });
  await localQa.markSynced([for (final e in unsynced) e.id]); // after 2xx only
  ```

## 2. The `synced` flag lifecycle

1. Capture question + approved answer locally with `synced=false`.
2. Upload batch → server returns ACK with accepted ids + server `updatedAt`.
3. On 2xx: `synced=true` for ACKed ids; store server `updatedAt`/`version`.
4. On failure/offline: keep `synced=false`, exponential backoff, retry next
   window. Never clear the outbox on failure.
5. Edits create a new `version`/`updatedAt` and reset `synced=false` so the
   correction flows up; deletes send a tombstone `{id, deleted:true}` and the
   host later calls `removeQaPairs([id])` after applying the server merge.

## 3. What the app must receive DOWN (server → device)

- Server merges A→Z across all mindsets/phrasings/languages into one
  canonical bundle (`bundleVersion`, `syncedUpTo`). Every device downloads the
  same merged set so each SDK learns every phrasing ("book event" /
  "book merchandise / package / activities" in en/hi/te/nl/fr/es).
- Host applies it:
  ```dart
  final merged = await api.get('/v1/qa:merged?since=$lastBundleVersion');
  final bundle = QaTrainingBundle.fromJson(merged); // accepts compact keys too
  final r = await engine.ingestKnowledge(bundle); // newer updatedAt/version wins
  lastBundleVersion = bundle.bundleVersion; // persist host-side
  ```
- Conflict rule: higher `version` wins, tie → newer `updatedAt` wins (SDK
  enforces this in `KnowledgeStore`). Server is source of truth for content;
  device is source of truth for `synced` bookkeeping.

## 4. When to sync (host schedules all of it)

- App launch (foreground): quick delta download → `upsertQaPairs`.
- Daily (or WorkManager/BGTask): full upload of `synced==false` + delta/full
  download. Also opportunistically mid-flow at a natural seam (e.g. after
  help-center close) — never blocking the answer path (`askKnowledge` is
  local and instant).
- After sync, call the SDK exactly once per bundle/delta; then drop the
  payload (or keep only `exportKnowledgeCompact()` cache). Don't poll the
  SDK — it has no network.

## 5. End-to-end example (Joyce / WhatsApp pattern)

1. Day 1: A asks 10 event questions (Telugu + English) → stored
   `synced=false` → uploaded overnight → flagged `synced`.
2. Day 2: B asks 100 (10 repeats + 90 new in Hindi/Dutch) → only 90 uploaded.
3. Server merges 10 + 90 + older C–Z into `bv=2026-11-03`.
4. Every device downloads `bv=2026-11-03` on next launch and calls
   `ingestKnowledge`; user A can now ask B's package/activity questions and
   gets same-language answers from the local index — no API call at ask time.

## 6. Server notes (host backend)

- Store Q&A only (`id, question, answer, lang, category, updatedAt, version,
  appId`). Index on `(normalized_question, lang)` for dedupe; keep per-lang
  counts to spot missing translations.
- Never store who asked what. Rate-limit uploads, validate
  `id/question/answer/lang` non-empty, cap answer length, strip PII with a
  scrubber before persisting.
- Serve `/qa:upload` (accept batch, return ACK ids) and `/qa:merged`
  (`since=bundleVersion` → full or delta + new `bundleVersion`).

## 7. What the SDK does with it (for reference only)

`ingestKnowledge` → dedupe by `question|lang` → compact store (cap 5000,
oldest-first eviction) → `askKnowledge(question, lang)` answers same-lang
(exact 1.0, fuzzy ≥ 0.35, else null) → optional
`automationHintForQa` → existing `AutomationEngine`. Model download/choice
via SDK Firebase Remote Config is untouched.
