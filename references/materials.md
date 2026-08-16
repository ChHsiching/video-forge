# Material pipelines

Per-type processing, the review gates, and the verification mechanics.

## Audio / video material

1. **Transcribe** with the whisperx pipeline (`cook transcribe` if the video-cook CLI is installed, else whisperx directly). Whole file in one call — chunking breaks sentence alignment. CPU large-v3 runs ~0.5-0.7× realtime; launch it in the background and do intake meanwhile.
2. **Speaker timeline** — no diarization needed at first pass: map turns by reading the transcript (host asks, guest explains); hand-annotate a coarse speaker segment list. For avatar-highlight visuals, ±5s accuracy reads fine.
3. **Envelope data** — for level meters/waveform visuals, extract per-100ms RMS. Calibrate in dB against the material's own speech percentiles (compute p25/p50/p95 and map that span to 0-1) — a fixed gain multiplier saturates the meter and users will notice it "doesn't follow the voice".
4. **AV sources that are "video"**: check a few far-apart frames before assuming motion — official podcast uploads are often a single static frame plus audio, which changes the whole design (and frees you from video decode in every render).

## URL / article material

- Fetch the page; JS-rendered pages return empty via plain fetch — drive a real browser bridge.
- Capture source metadata (author, title, URL, publish date) for attribution and later fact-checking.
- Run a research subagent on the topic to collect verifiable facts, numbers, and proper-noun spellings BEFORE any text goes on screen. Anything the research cannot confirm from an authoritative source is UNVERIFIED — surface it to the user, never silently render it.

## Gate mechanics (all gates)

- **Round structure**: fresh subagent reads every cue end-to-end, checks every proper noun in context (web-searching anything it questions), reports numbered defects → router fixes each by hand → new fresh subagent reruns the FULL read. Repeat until a round reports zero. Spot-checking fixed lines is not a pass; the fix itself can introduce defects.
- **Alignment blind spot**: count-only verifiers (n cues = n lines) pass while every line is off by one. Always also compare timestamps byte-for-byte against the source SRT, and spot-read EN[N]↔ZH[N] pairs at intervals.

## Translation (when subtitles are bilingual or localized)

- **Terminology**: ecosystem vocabulary the audience would look up stays in English (skill names, tool names, system terms like `spec`/`agent`/`ticket`); everyday words translate. When a term is both (e.g. a tool's tickets vs generic tickets), keep the ecosystem term English and gloss it in Chinese at first mention.
- **Cue boundaries**: commands, shortcuts, product names are atomic — never split across cues. Chinese follows Chinese sentence boundaries, not the English cue grid.

## AI-flavor gate (all on-screen text)

One dedicated pass over subtitles, cards, covers, and publish copy hunting:

- machine-compound words nobody says aloud (a coined "interrogation-meeting" style compound is the tell — replace with what a person would say)
- translated-English constructions (inverted negation, "arrive at a term", adverb-fronted praise)
- stock LLM phrasing, filler transitions, lists of exactly three
- card text relying on auto-wrap — break lines at semantic units instead

Run it as its own fresh-subagent round with a keep-English glossary attached (so it flags real issues, not approved terms), then hand-fix line by line.

## Fact verification checklist

Every number, claim, name, and quote destined for the screen gets cross-checked against an authoritative source (official repo, primary article, the author's own docs). Verified facts carry their source; the rest are UNVERIFIED. The storyboard stage should only use the verified list.
