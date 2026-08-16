---
name: video-forge
description: Turn any raw material — a URL, article, image gallery, audio podcast, or video file — into a finished, publishable video. Use whenever the user provides material of any kind and wants a video made from it, says "make a video from this" / 做视频 / 可视化 / 视频化, wants to visualize a podcast, article, or page, or asks what it takes to turn content into a video. This skill runs the intake interview, processes the material (transcription with review gates, fact verification, translation), then hands off to remotion-video-director for the build. For from-scratch motion design with no source material, go directly to remotion-video-director instead.
---

# video-forge

You are the **router** that turns source material into a finished video. The creative build belongs to `remotion-video-director`; your job is everything upstream (material, intake, gates) and downstream (render strategy, covers, platform variants, publish copy) of it.

```
material → ingest → intake interview → build-ready gates → director handoff → delivery
```

## The scope/shape boundary

Every decision in this pipeline belongs to exactly one side:

- **Scope is yours** — which part of the material becomes the video: full length vs highlights vs full-plus-clips, subtitle language, the visualization form the material supports, audience wording level, platform targets. `remotion-video-director` assumes the video's shape is already decided when it starts.
- **Shape is the director's** — creative direction, pacing, music, look, scene design. It asks these itself; pre-asking them in your interview steals its job and bores the user with duplicate questions.

When the director's Phase 1 asks "duration constraints", feed it the scope answers from intake — never re-open them.

## Step 0 — Probe dependencies

Check these skills are discoverable (by their descriptions being present):

- `remotion-video-director` — required. Without it, stop and give the install command: `npx skills add <owner>/remotion-video-director` (resolve the owner at install time).
- `remotion-4k-polish` — required before any 4K final render. Point the user to install if missing.
- `tts-forge` — required only when material has no audio track and the user wants voiceover.

## Step 1 — Ingest material

Dispatch by what the user handed you, then read `references/materials.md` before processing:

| Material | First moves |
|---|---|
| Audio / video file | Transcribe (whisperx pipeline), then speaker timeline + envelope data |
| URL (page / article / post) | Fetch content; JS-rendered pages need a real-browser bridge; capture source metadata |
| Images | Inventory as supplementary assets (avatars, references) — an image set alone is rarely a video's sole content; confirm intent in intake |

Done when: a usable content source exists on disk (transcript, article text, or asset inventory) plus source metadata (author, URL, title) for attribution.

## Step 2 — Intake interview

Ask these six categories with wording adapted to the material — a fixed questionnaire produces stupid questions. Ask through the host's structured question tool when one exists, with visual previews for form options; users pick better between concrete variants than from prose.

1. **Scope** — full / highlights / full + clips
2. **Subtitles** — language(s), burn-in vs soft
3. **Form** — which visualization shapes this material supports (derive options from the material analysis; never a fixed menu)
4. **Audience & wording red lines** — beginner vs expert, terminology handling, information-density preference (this is where the "no dead air / every N seconds something happens" red line comes from — it only exists if the user cares)
5. **Platform & specs** — target platforms, resolution/fps; this decides the deliverable list and variants
6. **Voiceover** — only when the material has no audio track: which TTS route → API key → voice audition, all inside `tts-forge`

The full question guide and the **director brief** format live in `references/intake.md` — read it before interviewing. Done when: every category has an answer the user gave or explicitly defaulted.

## Step 3 — Material to build-ready

Three gates between raw material and the director handoff. All are multi-round, fresh-subagent, full-pass reviews — fix everything a round finds, then rerun the whole gate until a round finds zero. A spot-check of fixed lines is never a gate pass.

- **Terminology gate** (transcribed or translated material): every proper noun, product name, and system term verified in context; ecosystem vocabulary stays in English when the audience would look it up that way.
- **AI-flavor gate** (any text that will appear on screen): subtitles, cards, covers, publish copy — spoken-register, no stock phrasing, semantic line breaks in cards.
- **Fact verification**: every number and claim destined for the screen cross-checked against authoritative sources by a research subagent; anything unconfirmable is marked UNVERIFIED and shown to the user before it renders.

Mechanics and the alignment blind spots (count-only checks miss cue drift) are in `references/materials.md`. Done when: all gates have a zero-defect pass and timestamps still match the source byte-for-byte.

## Step 4 — Director handoff

Assemble the director brief — the single artifact that carries everything intake and the gates produced. Its format is in `references/intake.md`. Then load `remotion-video-director`, enter at its Phase 2 (Scenario Design) with the brief as input, and let it own design, build, and its review loops. Stay available to answer scope-derived questions from intake answers.

## Step 5 — Delivery

These are defaults you do, not questions you ask:

- **Check render first** — render the composition at 540p (≈4× faster than 1080p) and have the user confirm content before any expensive final render. Text fixes at this stage cost minutes; after the 4K render they cost hours.
- **Final render** — at 4K, read `remotion-4k-polish` now and follow its path choice. For long videos: segmented rendering, resume-on-restart, integrity check every segment before concat.
- **Covers** — two ratios (16:9 + 4:3), independently designed per ratio (a 4:3 cover is its own layout, never a rescaled 16:9), large type only, no small text.
- **Platform variants** — e.g. the bilibili triple-action card rendered as a composition props variant inserted before the outro, never file-concatenated; endings stay tight (video ends when the music ends — no silent tail) for completion rate.
- **Publish copy** — per-platform titles, five-part description, chapters.

The full playbook is in `references/delivery.md`. Done when: deliverables + covers + publish copy are on disk, ffprobe specs match the intake answers, and the ending frames of every variant have been spot-checked.
