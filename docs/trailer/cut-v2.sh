#!/bin/bash
# The beta trailer's second iteration (F 2026-11-11: wide landmarks, the time and the weather
# changing on the Palace, the helicopter coming in to the stadium, the club's ring, a police chase, a
# boat jump by the Bulwary, the HUD in the gameplay shots only, music take 4).
# Usage: docs/trailer/cut-v2.sh TAKES_DIR OUT.mp4
# TAKES_DIR holds one mp4 per take (tools/trailer_cloud.sh or tools/trailer.sh final); a take may be
# rendered at a lower frame rate when the cut plays it faster (the flights): `speed` below.
# The cut follows the music's bars (120 bpm, a bar is 2 s): the theme comes in at 16 s, the final
# hit at 32 s, where the end card takes over (a take shorter than its slot holds its last frame).
# Needs ffmpeg with drawtext.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
takes=${1:?takes dir}
out=${2:?out.mp4}
font=${FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf}

# take:start:length:speed:caption (start in the take's own seconds; length on screen; speed 2 plays
# the take twice as fast; the caption, if any, sits low left like a title).
SHOTS=(
	"old_town_fly:0.4:4:1.5:THE REAL WARSAW."
	"skyline:3.0:4:1.75:"
	"kebab2:5.5:3:1:"
	"boat2:6.5:3:1:"
	"heli_stadium:0.6:4:2.5:"
	"time_lapse:0.8:5:2.7:DAY. NIGHT. RAIN."
	"chase2:8.0:3:1:GENTLE POLICE. NEVER GAME OVER."
	"club2:3.5:3:1:"
	"castle_night:0.3:3:1.5:"
	"card:0.3:6:1:"
)

inputs=()
chain=""
n=0
for shot in "${SHOTS[@]}"; do
	IFS=: read -r take ss len speed cap <<<"$shot"
	src=$(echo "$len * $speed + 0.2" | bc -l)
	inputs+=(-ss "$ss" -t "$src" -i "$takes/$take.mp4")
	f="setpts=(PTS-STARTPTS)/$speed,fps=30,tpad=stop_mode=clone:stop_duration=2,trim=duration=$len,setpts=PTS-STARTPTS,scale=1920:1080:flags=lanczos,setsar=1,format=yuv420p"
	if [[ -n $cap ]]; then
		f+=",drawtext=fontfile=$font:text='$cap':fontsize=60:fontcolor=white:borderw=3:bordercolor=black@0.85"
		f+=":shadowx=5:shadowy=5:shadowcolor=0xff2d95@0.85:x=80:y=h-160"
		f+=":alpha='min(1,min(t/0.25,($len-t)/0.25))'"
	fi
	chain+="[$n:v]$f[v$n];"
	n=$((n + 1))
done
cat=""
for ((i = 0; i < n; i++)); do cat+="[v$i]"; done
chain+="${cat}concat=n=$n:v=1:a=0[v];"
chain+="[$n:a]atrim=0.48:38.48,asetpts=PTS-STARTPTS,afade=t=out:st=36.5:d=1.5[a]"
ffmpeg -v error -y "${inputs[@]}" -i "$here/music-take4.mp3" -filter_complex "$chain" \
	-map "[v]" -map "[a]" -shortest -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p \
	-c:a aac -b:a 256k -movflags +faststart "$out"
echo "$out: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out") s"
