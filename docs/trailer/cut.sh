#!/bin/bash
# Cuts the beta trailer from the --trailer takes (Movie Maker mp4s, 1920x1080, 60 fps) and the
# music (music-take4.mp3, beside this script). Usage: docs/trailer/cut.sh TAKES_DIR OUT_DIR
# TAKES_DIR holds palace_time.mp4 heli_dive.mp4 drift_day.mp4 drift_night.mp4 old_town.mp4 card.mp4.
# Writes OUT_DIR/around-warsaw-beta-38s.mp4 and OUT_DIR/around-warsaw-beta-30s.mp4.
# Needs ffmpeg. The cuts land on the music's bars (120 bpm: a bar is 2 s); see README.md.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
takes=${1:?takes dir}
out=${2:?out dir}
mkdir -p "$out"

# cut NAME MUSIC_FILTER SHOT... ; SHOT = take:start:length (seconds in the take)
cut() {
	local name=$1 music=$2
	shift 2
	local inputs=() chain="" n=0 hold=0
	for shot in "$@"; do
		IFS=: read -r take ss len <<<"$shot"
		inputs+=(-ss "$ss" -t "$len" -i "$takes/$take.mp4")
		chain+="[$n:v]setpts=PTS-STARTPTS,fps=60,format=yuv420p[v$n];"
		n=$((n + 1))
	done
	local cat=""
	for ((i = 0; i < n; i++)); do cat+="[v$i]"; done
	# The last shot (the card) holds its last frame to the end of the music.
	chain+="${cat}concat=n=$n:v=1:a=0[cv];[cv]tpad=stop_mode=clone:stop_duration=2[v];"
	chain+="[$n:a]$music[a]"
	ffmpeg -v error -y "${inputs[@]}" -i "$here/music-take4.mp3" -filter_complex "$chain" \
		-map "[v]" -map "[a]" -shortest -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p \
		-c:a aac -b:a 256k -movflags +faststart "$out/$name"
	echo "$name: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out/$name") s"
}

# 38 s: day (0-12), golden to dusk (12-16), the theme and the helicopter (16-24), night (24-32),
# the card on the final hit (32).
cut around-warsaw-beta-38s.mp4 \
	"atrim=0.48:38.48,asetpts=PTS-STARTPTS,afade=t=out:st=36.5:d=1.5" \
	palace_time:0.3:4 old_town:0.5:4 drift_day:1:4 palace_time:5:4 \
	heli_dive:0.5:8 drift_night:1:4 palace_time:10:4 card:0:5.5

# 30 s: the music with bars 3-5 cut out (theme at 10 s, final hit at 26 s).
cut around-warsaw-beta-30s.mp4 \
	"atrim=0.48:42,asetpts=PTS-STARTPTS,asplit[m1][m2];[m1]atrim=0:4,asetpts=PTS-STARTPTS[ma];[m2]atrim=10:36.1,asetpts=PTS-STARTPTS[mb];[ma][mb]acrossfade=d=0.03:c1=tri:c2=tri,atrim=0:30,afade=t=out:st=28.8:d=1.2" \
	palace_time:0.3:3 old_town:1:3 drift_day:1:4 heli_dive:2.5:6 \
	palace_time:7:4 drift_night:1:6 card:0.3:4.2
