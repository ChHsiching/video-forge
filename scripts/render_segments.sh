#!/bin/bash
# Segmented parallel render driver for long Remotion videos, with the
# session-proven safeguards baked in:
#   - frame-exact segments, stream-copy concat (zero quality loss)
#   - skip-existing resume (a crash costs only the in-flight segment)
#   - staggered queue starts (process-spawn spikes collide otherwise)
#   - per-segment retry (transient ffmpeg spawn failures happen under load)
#   - moov integrity check BEFORE concat (killed segments never join the master)
#
# Usage:
#   render_segments.sh <entry.ts(x)> <CompositionId> <total-frames> <out-mp4> \
#                      [--segments N] [--queues N] [--concurrency N]
#                      [-- extra render args, e.g. --scale=2 --props='{"x":1}']
set -eu
ENTRY="${1:?entry}"; COMP="${2:?composition id}"; TOTAL="${3:?total frames}"; OUT="${4:?out.mp4}"
shift 4
SEGMENTS=12; QUEUES=2; CONCURRENCY=8
while [ $# -gt 0 ]; do
  case "$1" in
    --segments) SEGMENTS="$2"; shift 2 ;;
    --queues) QUEUES="$2"; shift 2 ;;
    --concurrency) CONCURRENCY="$2"; shift 2 ;;
    --) shift; break ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
EXTRA="$*"
SEG=$(( (TOTAL + SEGMENTS - 1) / SEGMENTS ))
DIR="$(dirname "$OUT")/segments"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$DIR"

render_one() {
  local i=$1
  local A=$((i * SEG)); local B=$(((i + 1) * SEG - 1)); [ $B -ge $TOTAL ] && B=$((TOTAL - 1))
  local F="$DIR/seg_$(printf '%03d' $i).mp4"
  [ -s "$F" ] && { echo "skip seg$i"; return 0; }
  echo "start seg$i [$A-$B] $(date +%H:%M:%S)"
  npx remotion render "$ENTRY" "$COMP" "$F" --codec=h264 $EXTRA \
    --concurrency=$CONCURRENCY --frames=$A-$B \
    || { sleep 10; npx remotion render "$ENTRY" "$COMP" "$F" --codec=h264 $EXTRA \
           --concurrency=$CONCURRENCY --frames=$A-$B; }
  echo "done seg$i $(date +%H:%M:%S)"
}

# split segments round-robin into per-queue lists, staggered starts
LISTS=$(seq 0 $((SEGMENTS - 1)) | awk -v q=$QUEUES '{ print >> ("'"$DIR"'/q" (NR % q) ".list") }')
pids=()
for q in $(seq 0 $((QUEUES - 1))); do
  (
    sleep $((q * 40))
    while read -r i; do render_one "$i"; done < "$DIR/q$q.list"
  ) &
  pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done
rm -f "$DIR"/q*.list

# integrity gate before concat — refuses broken segments
bash "$SKILL_DIR/scripts/check_segments.sh" "$DIR" >/dev/null || {
  echo "integrity check failed — re-run this script after fixing segments above" >&2
  bash "$SKILL_DIR/scripts/check_segments.sh" "$DIR"; exit 1
}

: > "$DIR/concat.txt"
for i in $(seq 0 $((SEGMENTS - 1))); do
  echo "file '$DIR/seg_$(printf '%03d' $i).mp4'" >> "$DIR/concat.txt"
done
ffmpeg -y -v error -f concat -safe 0 -i "$DIR/concat.txt" -c copy "$OUT"
echo "RENDER_DONE $OUT $(date +%H:%M:%S)"
