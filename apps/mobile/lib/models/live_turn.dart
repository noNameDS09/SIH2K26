/// One turn of the real `POST /v1/speech/live/turn` cataloger
/// (`apps/api/src/kalasetu_api/routers/speech.py`). This is a **stateless,
/// transcript-based turn** — the client sends the last transcript plus the
/// opaque `session` blob it was given, and gets back the next thing to
/// speak plus the same blob to send next time. There is no `listing_id`
/// and no audio upload at this endpoint; STT happens separately first.
class LiveTurn {
  const LiveTurn({
    this.session = const {},
    this.speak = '',
    this.question = '',
    this.reread,
    this.phase = 'interviewing',
    this.done = false,
    this.listing,
    this.table = const [],
  });

  /// Opaque — round-trip this back on the next call unchanged (plus the
  /// new transcript). Also contains `slots: {name: {raw,value,confirmed,
  /// provenance}}` for every slot, which is what a live checklist UI reads.
  final Map<String, dynamic> session;
  final String speak;
  final String question;
  final String? reread;
  final String phase; // interviewing | confirming | copy | complete
  final bool done;

  /// Only non-null when [done]. Each field is wrapped as
  /// `{value, provenance}` (including entries in `fields`) — callers must
  /// unwrap before treating this as a flat `Listing`.
  final Map<String, dynamic>? listing;

  /// Flat `{field, value, raw_transcript, source, confidence}` rows —
  /// only populated once [done].
  final List<Map<String, dynamic>> table;

  Map<String, dynamic> get slots =>
      (session['slots'] as Map?)?.cast<String, dynamic>() ?? const {};

  static LiveTurn fromJson(Map<String, dynamic> json) => LiveTurn(
        session: (json['session'] as Map?)?.cast<String, dynamic>() ?? const {},
        speak: json['speak'] as String? ?? '',
        question: json['question'] as String? ?? '',
        reread: json['reread'] as String?,
        phase: json['phase'] as String? ?? 'interviewing',
        done: json['done'] == true,
        listing: (json['listing'] as Map?)?.cast<String, dynamic>(),
        table: (json['table'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
      );
}

/// Unwraps the `{value, provenance}`-wrapped `listing` from a finished
/// cataloger session into the flat shape `PATCH /v1/listings/{id}` expects
/// (`ListingPatchPayload`: plain strings/maps, no provenance envelope —
/// the API drops per-field provenance on write; pricing recomputes its own
/// provenance fresh via `POST /v1/listings/{id}/price` regardless).
Map<String, dynamic> flattenCatalogerListing(Map<String, dynamic> wrapped) {
  dynamic unwrap(dynamic v) => v is Map && v.containsKey('value') ? v['value'] : v;

  final wrappedFields = (wrapped['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
  final flatFields = <String, dynamic>{
    for (final entry in wrappedFields.entries) entry.key: unwrap(entry.value),
  };

  return {
    'title_hi': unwrap(wrapped['title_hi']),
    'title_en': unwrap(wrapped['title_en']),
    'desc_hi': unwrap(wrapped['desc_hi']),
    'desc_en': unwrap(wrapped['desc_en']),
    'fields': flatFields,
    'cluster': wrapped['cluster'],
  };
}
