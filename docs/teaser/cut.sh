#!/usr/bin/env bash
# The Instagram Reels teaser (F, 2026-11-19): N one-second game shots cut on the music's beats, then
# the 2 s end card on the final hit. 3 shots make 5 s (music-5s.m4a), 5 shots 7 s (music-7s.m4a). README.md beside this file has the plan.
#
#   docs/teaser/cut.sh CLIPS_DIR ART_DIR OUT.mp4
#
#   CLIPS_DIR  the clips SHOTS names, from tools/clip.sh (1080x1920, 30 fps)
#   ART_DIR    tools/reel/render.mjs ART_DIR --card-frames=2 (card/f_0000.png ...)
#
# Edit SHOTS to re-time the cut without re-rendering anything: NAME:START (seconds into that clip).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
clips=${1:?CLIPS_DIR}; art=${2:?ART_DIR}; out=${3:?OUT.mp4}
FPS=30
SHOTS=(${SHOTS:-palm2:0.5 skyline:1.0 spire:0.5 kopernik:0.5 drive:0.5})   # each plays 1.0 s; the card at N s
CARD=2.0

inputs=(); chains=""; i=0
for s in "${SHOTS[@]}"; do
	inputs+=(-ss "${s#*:}" -t 1.0 -i "$clips/${s%%:*}.mp4")
	chains+="[$i:v]fps=$FPS,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,trim=0:1.0,setpts=PTS-STARTPTS[v$i];"
	i=$((i + 1))
done
inputs+=(-framerate $FPS -i "$art/card/f_%04d.png")
chains+="[$i:v]trim=0:$CARD,setpts=PTS-STARTPTS,format=yuv420p,setsar=1[v$i];"
music=$i; i=$((i + 1))
total=$(( ${#SHOTS[@]} + 2 ))
inputs+=(-i "$here/music-${total}s.m4a")
concat=""; for ((k = 0; k < music + 1; k++)); do concat+="[v$k]"; done
# A two-frame flash on the cut to the card: the hit.
chains+="${concat}concat=n=$((music + 1)):v=1:a=0,format=yuv420p,fade=t=in:st=0:d=0.1,"
chains+="curves=all='0/0.25 1/1':enable='between(t,${#SHOTS[@]}.0,${#SHOTS[@]}.067)'[v]"

ffmpeg -v error -y "${inputs[@]}" -filter_complex "$chains" -map "[v]" -map "$i:a" \
	-c:v libx264 -profile:v high -level 4.2 -preset slow -crf 17 -maxrate 14M -bufsize 28M \
	-pix_fmt yuv420p -r $FPS -g $FPS -c:a aac -b:a 192k -ar 48000 -ac 2 \
	-movflags +faststart -shortest "$out"
echo "$out: $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$out")"
