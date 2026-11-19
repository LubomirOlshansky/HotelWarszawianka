#!/usr/bin/env bash
# Teaser 2, "Warsaw 3 a.m." (F, 2026-11-19): the Centrum metro / Rondo Dmowskiego view at night in
# the rain, people under umbrellas, a live-camera overlay (tools/reel/live.html) and the ElevenLabs
# rain and city ambience. README.md beside this file has the plan.
#
#   docs/teaser2/cut.sh CLIPS_DIR ART_DIR OUT.mp4
#
#   CLIPS_DIR  the clips SHOTS names, from tools/clip.sh (1080x1920, 30 fps)
#   ART_DIR    node tools/reel/render.mjs ART_DIR --live-frames=7 (live/f_0000.png ...)
#
# SHOTS is NAME:START:LENGTH (seconds) per shot (F: one 5 s shot). PUSH is the slow
# push-in over the whole cut (1.0 = none, the default: F 2026-11-19 "no need for zoom").
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
clips=${1:?CLIPS_DIR}; art=${2:?ART_DIR}; out=${3:?OUT.mp4}
FPS=30
SHOTS=(${SHOTS:-metroF:2:7})
PUSH=${PUSH:-1.0}
# F 2026-11-19: the reel replays, so the sound loops (docs/teaser2/mix.sh) and is not faded out;
# FADE=1 brings back the 0.8 s fade at the end.
afade=()
[ "${FADE:-0}" = 1 ] && afade=(-af "afade=t=out:st=$(echo "${SHOTS[0]##*:} - 0.8" | bc):d=0.8")

inputs=(); chains=""; i=0; concat=""; total=0
for s in "${SHOTS[@]}"; do
	IFS=: read -r name start len <<<"$s"
	inputs+=(-ss "$start" -t "$len" -i "$clips/$name.mp4")
	chains+="[$i:v]fps=$FPS,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,trim=0:$len,setpts=PTS-STARTPTS[v$i];"
	concat+="[v$i]"; i=$((i + 1)); total=$(echo "$total + $len" | bc)
done
inputs+=(-framerate $FPS -i "$art/live/f_%04d.png"); ov=$i; i=$((i + 1))
inputs+=(-i "$here/${AMBIENCE:-ambience-7s.m4a}"); au=$i
# The push-in: scale up a little over the cut and crop the centre back to 1080x1920.
chains+="${concat}concat=n=$ov:v=1:a=0,scale=w='trunc(1080*(1+($PUSH-1)*t/$total)/2)*2':h=-2:eval=frame,crop=1080:1920,setsar=1[base];"
chains+="[base][$ov:v]overlay=0:0:shortest=1,format=yuv420p[v]"

ffmpeg -v error -y "${inputs[@]}" -filter_complex "$chains" -map "[v]" -map "$au:a" ${afade[@]} \
	-c:v libx264 -profile:v high -level 4.2 -preset slow -crf 17 -maxrate 14M -bufsize 28M \
	-pix_fmt yuv420p -r $FPS -g $FPS -c:a aac -b:a 192k -ar 48000 -ac 2 \
	-movflags +faststart -t "$total" "$out"
echo "$out: $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$out")"
