#!/usr/bin/env python3
"""Extract a per-100ms loudness envelope (JSON array) from an audio file,
calibrated in dB against the material's OWN speech percentiles.

Why the calibration is built in: a fixed gain multiplier saturates the meter —
speech sits pinned near max and viewers see "the meter doesn't follow the
voice". Mapping the material's p25..p95 dB span onto 0..1 gives natural
movement. This was debugged the hard way; do not remove.

Usage:
  python audio_envelope.py input.wav out.json        # any audio ffmpeg reads
"""
import argparse, json, math, subprocess


def pcm_rms_db(path: str):
    # decode to 8kHz mono s16le in memory — envelope fidelity needs no more
    r = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "s16le", "-ac", "1", "-ar", "8000", "-"],
        capture_output=True)
    if r.returncode != 0:
        raise SystemExit(r.stderr.decode()[-400:])
    import array
    pcm = array.array("h")
    pcm.frombytes(r.stdout)
    win = 800  # 100ms at 8kHz
    dbs = []
    for i in range(0, len(pcm) - win, win):
        chunk = pcm[i:i + win]
        rms = math.sqrt(sum(x * x for x in chunk) / len(chunk)) / 32768.0
        dbs.append(20 * math.log10(rms + 1e-9))
    return dbs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    args = ap.parse_args()

    dbs = pcm_rms_db(args.input)
    ordered = sorted(dbs)
    p25 = ordered[int(len(ordered) * 0.25)]
    p95 = ordered[int(len(ordered) * 0.95)]
    span = max(p95 - p25, 6.0)  # floor: near-silent material still moves a bit

    levels = [round(max(0.0, min(1.0, (db - p25) / span)), 3) for db in dbs]
    json.dump(levels, open(args.output, "w"))
    print(f"frames: {len(levels)} ({len(levels) * 0.1:.1f}s)  "
          f"p25={p25:.1f}dB p95={p95:.1f}dB span={span:.1f}dB")


if __name__ == "__main__":
    main()
