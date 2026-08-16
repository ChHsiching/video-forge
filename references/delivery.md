# Delivery playbook

Render strategy, covers, platform variants, publish copy. These are defaults — do them, and mention them, rather than asking.

## Check render → final render

Always render a cheap check version first and have the user confirm content:

- 540p (scale 0.5) renders ≈4× faster than 1080p — good enough to read every card and subtitle. (360p is not an option: one-third scale is not an integer multiple and the renderer rejects it.)
- Only after the user confirms content: final render. At 4K, `remotion-4k-polish` owns the path choice — read it before rendering.

## Long-video render strategy (anything over ~15 minutes)

- **Segmented rendering**: split into N frame-exact segments (each an independent encode), render sequentially or in 2-3 parallel instance queues (stagger starts ~40s so process-spawn spikes don't collide), concat with stream copy. Zero quality loss: same encoder settings per segment, no re-encode at the join.
- **Resume**: segments already on disk are skipped — a crashed run costs only the in-flight segment.
- **Integrity check before concat**: after ANY force-kill of render processes, ffprobe every existing segment (`moov atom not found` = the file was killed mid-finalize) and re-render the broken ones. "File exists" is not "file is complete".
- **Parallelism ceiling**: one render instance caps at ~4 cores (the screenshot pipeline is single-threaded); scale by adding instances, not tabs-per-instance, and watch RAM (~6-8GB per instance).
- **After a supervised kill**: run the moov check before relaunching. This one line has saved hours.

## Ending & completion rate

- Endings stay tight: the video ends when the music ends — fade the audio out over the outro and cut. Silent tails cost completion rate.
- Outro sequence budget: single-digit seconds per card; a "$ logout"-style sign-off needs ~3-4s total, never 15.
- Platform variant cards (e.g. bilibili triple-action) render as a **composition props variant** inserted before the outro — the variant is part of the timeline with native transitions. File-level concat of a separately rendered tail produces sample-rate mismatches and hard cuts; a props variant makes both versions from one codebase.

## Covers

- Two ratios per project: 16:9 (1920×1080) and 4:3 (1440×1080). **A 4:3 cover is its own layout** — vertical space runs out differently, so design it from scratch (move footnotes, re-center blocks, re-fit type); scaling a 16:9 layout down produces wrapped titles and clipped cards.
- Large type only — everything a thumbnail must communicate at ≥48px at 1080-scale. Small text on covers is invisible in feeds; write nothing you wouldn't read at 200px wide.
- The cover is an independent design, never a frame from the video and never the video's layout shrunken.
- Chinese title should be sans/bold (serif CJK reads thin at cover sizes) and at least as prominent as any English title — viewers read the language they know to decide what the video is.
- **Verify by reading, not by metric**: downsampled-pixel brightness checks are blind to thin/colored text (green prompt lines, gray footnotes — all below threshold). Downscale the full cover to ASCII art and read it; this catches wraps, overlaps, and missing elements that metrics pass.

## Publish copy

Per-platform deliverable, written after the video is final (facts on screen are then frozen):

- **Titles**: per platform, length checked against the real limits (bilibili allows 80 chars — don't self-cripple at 30; xiaohongshu ~20). A title tells the viewer what happens in the video, not a slogan.
- **Description** (long platforms): five-part structure in order — positioning line (who did what, one sentence of value), numbered hooks (why watch, with suspense), key-content list (· bullets, label: content), source block (author/original URL/related links), closing note (subtitle credit line).
- **Chapters**: platform field versions respect their limits (bilibili ≤10, xiaohongshu ≤15, YouTube free) with names ≤11 chars, plus one full descriptive list for a pinned comment.
- Plain text only inside paste blocks — platforms render markdown literally; bullets use `·`, never `-`.
- Verify counts with `len()` against each platform's counting rule before handing over.
