# Delivery playbook

Mechanics for render gates, timing, verification, audio, covers, platform variants, and publish copy. These are defaults — do them, and mention them, rather than asking. The gate order and the hard delivery checklist live in SKILL.md Step 5; this file explains how each item is executed.

## Render gates (mechanics)

- **Gate 1, stills**: one still per distinct layout/asset state (not per scene), presented as a labeled sheet. Approves content and assets.
- **Gate 2, cheap full render with audio**: 1080p, or 540p (scale 0.5) for long videos — roughly 2× faster than 1080p in practice, because per-frame overhead dominates at small sizes. (360p via scale is not an option: a decimal third of 1080 lands on a fractional height and the renderer rejects non-integer dimensions — stick to 0.5/0.75.) Approves content and timing.
- **Gate 3, final render**: at 4K, `remotion-4k-polish` owns the path choice — read it before rendering.

## Audio-first timing (narrated videos)

When narration is TTS and intake settled the timing authority as audio-first (the default), the timeline derives from audio, never from design estimates:

1. Write and gate the narration script, then **freeze** it. Every sentence changed after synthesis means re-synthesis, re-timing, and a re-render of everything downstream — confirm with the user before touching a frozen script.
2. Synthesize per-segment audio (tts-forge).
3. Derive timing from measured durations — **by running a script over the segment files, never by hand arithmetic** (hand-computed cumulative starts have produced real off-by-hundreds errors). The derivation, once implemented:
   - scene length = `ceil((segment_duration + pad) × fps)`, pad ≈ 0.7s breathing room
   - scene starts are cumulative; the last segment's end is the composition length
   - caption spans per scene: detect speech pauses (`ffmpeg silencedetect` at −32dB, ≥0.16s), place each cue boundary at the pause nearest its character-proportional estimate (fall back to the estimate when no pause within 0.7s), convert to frames
4. Scenes and captions consume the generated tables. Proportional rescaling of caption times desyncs against real speech pacing — re-anchor to pauses instead.

## Verification protocol

Content truth lives in the rendered file: a stale bundle renders stills fine while the video breaks, so stills alone never clear a delivery.

- Verify from the rendered MP4: extract frames and judge those.
- Blank-scene sweep: per scene, diff the 85%-through frame against the faded-out final frame — a near-zero diff means the scene renders empty. This one pass catches the whole "content invisible" bug class.
- Neutral vision prompts: ask what is present, never state the expected content — leading prompts get confident hallucinated confirmations.
- Textured or sparse layouts defeat mean-brightness checks; trust the pixel diff and neutral reads over threshold heuristics.

## Audio mix baseline

bilibili transcodes without loudness normalization — what you upload is what viewers hear; YouTube pulls down toward about −14 LUFS and never boosts. Targets for narration-led video:

- Integrated loudness: −16 LUFS ±1
- True peak: ≤ −1 dBTP
- Music bed: 12-18 dB under the voice; the high end when clarity matters
- Verify with an ebur128 three-window read: whole file, a speech window, a music-only window

## Long-video render strategy (anything over ~15 minutes)

**Maximize parallelism to the actual hardware — measure, then compute, never accept a default queue count:**

1. Probe: logical CPU count and FREE RAM (not total — a "cleaned" machine frees twice the queues).
2. Calibrate on the first render: an instance saturates ~3-4 cores regardless of `--concurrency` (architectural), but its RAM scales with output resolution (~6-8GB at 4K, less at 1080p) — measure one running instance, then compute `queues = min(floor(cores/4), floor(free_ram_gb / measured_instance_gb), remaining_segment_count)`. Two remaining segments means two queues; a third lane has nothing to render.

- **Segmented rendering**: split into N frame-exact segments (each an independent encode), render sequentially or in 2-3 parallel instance queues, concat with stream copy. Zero quality loss: same encoder settings per segment, no re-encode at the join.
- **Resume**: segments already on disk are skipped — a crashed run costs only the in-flight segment.
- `render_segments.sh` gates concat on the integrity check itself; a hand-driven segment run needs `scripts/check_segments.sh` first.

## Windows render environment

- A killed render leaves node/chrome-headless processes alive that lock partial outputs (`rm` reports "Device or resource busy"). Kill them first — `Get-CimInstance Win32_Process` filtered on `remotion` in the command line, `Stop-Process` each — then delete partials.
- Render commands run bare, no pipes: `… | tail` eats the real exit code and a failed render reports success.
- Pass `--port` explicitly — the renderer's internal server defaults to 3000, which collides with WSL port forwarding on dev machines.
- Keep `public/` lean: narration WAVs and screenshots pile into tens of MB and slow every bundle copy. On an intermittent copy timeout, retry once before diagnosing.

## Ending & completion rate

- The video ends when the music ends — fade the audio over the outro and cut. Silent tails and fade-to-black tails both cost completion rate: end on the card, hard cut.
- Sign-off card: ≤2s total, its animation done within ~1s, then straight to the end.
- Closing copy states a takeaway or next action; begging CTAs ("评论区说" / "comment below") read as filler — engagement prompts belong in the pinned comment.
- Platform variant cards (e.g. bilibili triple-action) render as a **composition props variant** inserted before the outro — the variant joins the timeline with native transitions, and both platform versions build from one codebase. (File-level concat of a separately rendered tail is the fallback: it needs aligned streams — e.g. a silent audio track on the tail — and re-checking the join.) A triple-action card keeps the same budget: icons pop in fast and asynchronously within ~1s, hard end at ≤2.5s.

## Covers

- Explore before finalizing: produce 3-4 covers with genuinely different visual concepts — different metaphor and information organization. Rearranging the same elements, or reusing video components (a scene's terminal card, the header bar), yields variations of one cover rather than options; the user picks from real alternatives, then the chosen concept gets built out in every required ratio.
- One cover per ratio the intake platform list implies — typically 16:9 (1920×1080) and 4:3 (1440×1080) for bilibili/xiaohongshu; a YouTube-only job needs no 4:3. **A 4:3 cover is its own layout** — vertical space runs out differently, so design it from scratch (move footnotes, re-center blocks, re-fit type); scaling a 16:9 layout down produces wrapped titles and clipped cards.
- Large type only — everything a thumbnail must communicate at ≥48px at 1080-scale. Small text on covers is invisible in feeds; write nothing you wouldn't read at 200px wide.
- Chinese title should be sans/bold (serif CJK reads thin at cover sizes) and at least as prominent as any English title — viewers read the language they know to decide what the video is.
- **Verify by reading, not by metric**: downsampled-pixel brightness checks are blind to thin/colored text (green prompt lines, gray footnotes — all below threshold). Downscale the full cover to ASCII art and read it; this catches wraps, overlaps, and missing elements that metrics pass.
- The cover is an independent design — a frame from the video is not a cover.

## Publish copy

Per-platform deliverable, written after the video is final (facts on screen are then frozen). Full spec below — kept in sync with video-subtitle's SKILL.md Step 6 (same rules maintained there for cook runs; when either changes, change both).

**Plain text inside paste blocks.** Platforms render markdown literally: `**bold**` shows as asterisks, `-` markers show as hyphens. The upload.md file may use markdown for its own sections; the fenced paste-block content is plain text with line breaks, list items as `·` or `1. 2. 3.`.

**Titles — multiple, per platform:**

- **bilibili**: professional, ~30 chars, telling the viewer what happens in the video (e.g. "从零搭建一个全新项目"), with the author's identity when recognizable. A title the viewer needs the description to understand is the wrong title.
- **xiaohongshu**: ≤20 chars, same professional tone, zero marketing language ("大佬带你", "效率翻倍").
- **YouTube**: may carry "(双语字幕)" or the English title variant.

**Description — three versions:**

1. **Full (bilibili/YouTube)**, five parts in order:
   - 定调句 (1-2 sentences): author + what they did + one-sentence value — "X 用 Y 做了 Z", never "来自 X 的讲解".
   - 看点 (numbered): hooks with a teaser, not a table of contents — each item carries suspense, not a flat fact.
   - 关键内容 (`·` list): key beats as "label: content" pairs — a scannable index, easier than a flat list.
   - 来源 (`·` list): `来源：` / `· 作者：` / `· 原视频：` / `· 网站/仓库：` — structured, never inline.
   - 结尾话术 (verbatim): `字幕：AI 辅助转录 + 翻译并经人工校对。如有不准确之处，欢迎指出。` — for original-narration videos (no translation), the honest adaptation: `字幕与口播：AI 辅助制作并经人工校对。如有不准确之处，欢迎指出。`
2. **xiaohongshu pinned comment (≤300 chars, every character counted as the platform counts)**: the first three paragraphs compressed plus the closing note. Leave out 看点, 关键内容, and links — they eat the budget. Verify with `len()`; compress until it fits.
3. **xiaohongshu body (≤100 chars)**: one sentence — who published what, the core topic, why watch. No metadata ("双语字幕" belongs in the pinned comment). Verify with `len()`.

**Chapters — four versions, all produced (a hard checklist, not a menu):**

1. bilibili platform field (≤10): `HH:MM:SS` + name ≤11 chars
2. xiaohongshu platform field (≤15): same format
3. YouTube platform field: same format
4. Pinned-comment full list: `HH:MM:SS` + one descriptive sentence per chapter, no length limit

Timestamps come from the actual delivered timeline (an audio-first run reads the generated timing table). Tone throughout: translator, not promoter.

**Verify before handover**: title lengths, chapter counts and name lengths, description char counts — each against its platform's counting rule, by `len()`.
