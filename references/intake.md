# Intake guide

How to run the six-question interview, and the director brief that comes out of it.

## What you ask vs what the director asks

Never pre-ask the director's questions — it will ask them itself in its Phase 1, and asking twice trains the user to skim. Its territory: purpose, creative audience framing, desired action, creative direction (style family), reference videos, background music, duration-within-scope.

Your territory is everything the material and the publish plan contribute:

| # | Category | What to settle | Session-proven example phrasings |
|---|---|---|---|
| 1 | Scope | full / highlights / full + short clips | "59 分钟完整，画面随内容变化，当播客听" vs "5-10 分钟精华" |
| 2 | Subtitles | language(s), burn-in vs soft-sub files | bilingual / Chinese-only / English-only |
| 3 | Form | which visualization shapes THIS material supports | podcast → speaker panels + annotation cards; article → information-card flow; product page → demo walkthrough. Present 2-3 concrete variants with ASCII previews |
| 4 | Audience & wording red lines | beginner vs expert; terminology handling; density preference | "观众是小白，先人话后术语，禁缩词怪词" and/or "不要空白等待，任意 N 秒窗口至少一次视觉事件" — record density as a number if given |
| 5 | Platform & specs | which platforms, resolution/fps | decides variants (bilibili triple card? xiaohongshu cover?) and render target |
| 6 | Voiceover | only for silent material | route choice → API key → voice audition, hand to tts-forge |

Two phrasing rules earned the hard way:

- **Form options must be derived from the material, every time.** A fixed menu fits last project and betrays this one. Read the transcript/article first, then design the 2-3 forms it actually supports.
- **Use the structured question tool with previews.** Users choose between concrete variants decisively and answer open prose vaguely. When they answer a form question with extra requirements ("very good, but make it dense, assume beginners"), those rider requirements are intake gold — record them in the brief.

## The director brief

One page, handed to remotion-video-director as it enters its Phase 2. Fields:

```
MATERIAL   what the source is; duration/length; author + URL for attribution
SCOPE      full/highlights answer; clip list if any
AUDIENCE   who watches; wording level; terminology rules (what stays English and why)
RED LINES  density (as a number if given); tone rules; anything the user vetoed
SUBTITLES  language(s); burn-in or soft
FORM       chosen visualization form + why the material supports it
PLATFORMS  target platforms; resolution/fps; required variants (e.g. bili triple card)
FACTS      verified key numbers/claims for on-screen use; UNVERIFIED list if any
ASSETS     speaker avatars/photos, source images, logo — what exists, what's cleared
AUDIO      original track / TTS plan (tts-forge output) / none
```

The brief replaces the director's Phase 1 discovery — say so when handing off, so it starts at Phase 2 instead of re-interviewing.
