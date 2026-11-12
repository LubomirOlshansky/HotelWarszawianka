#!/bin/bash
# Cuts the beta trailer from the --trailer takes (Movie Maker mp4s, 1920x1080, 60 fps) and the
# music (music-take4.mp3, beside this script). Usage: docs/trailer/cut.sh TAKES_DIR OUT_DIR
# TAKES_DIR holds one mp4 per take tools/trailer.sh makes (the shot lists below name them).
# Writes OUT_DIR/around-warsaw-beta-38s.mp4 and OUT_DIR/around-warsaw-beta-30s.mp4.
# Needs ffmpeg. The cuts land on the music's bars (120 bpm: a bar is 2 s); see README.md.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
takes=${1:?takes dir}
out=${2:?out dir}
mkdir -p "$out"

# cut NAME MUSIC_FILTER SHOT... ; SHOT = take:start:length[:speed] (start in the take's seconds,
# length on screen; speed 2 plays the take twice as fast, for the flyovers)
cut() {
	local name=$1 music=$2
	shift 2
	local inputs=() chain="" n=0 hold=0
	for shot in "$@"; do
		IFS=: read -r take ss len speed <<<"$shot"
		speed=${speed:-1}
		inputs+=(-ss "$ss" -t "$(echo "$len * $speed" | bc -l)" -i "$takes/$take.mp4")
		chain+="[$n:v]setpts=(PTS-STARTPTS)/$speed,fps=60,scale=1920:1080:flags=lanczos,setsar=1,format=yuv420p[v$n];"
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

# F (2026-11-10, after the first cut): fast like the day-two version, gameplay with the HUD and the
# game's jokes, a cut every 1.5-3 s, the flyovers at 2-4x. 38 s: the day's jokes (0-14), the
# Palace from day to night at 4x into the theme (16), the night (16-32), the card on the final hit.
cut around-warsaw-beta-38s.mp4 \
	"atrim=0.48:38.48,asetpts=PTS-STARTPTS,afade=t=out:st=36.5:d=1.5" \
	old_town:0.5:2:2 kebab:1:3 ride:2:2 pullover:2:2 boat:3.5:2 vistula:1:3 palace_time:3:2:4 \
	heli_dive:0.5:3:1.5 chase:1:3 club:5.5:2 drag:3:3 heli_play:1:2 \
	drift_night:1:1.5 palace_time:11:1.5 card:0:5.5

# 30 s: the music with bars 3-5 cut out (theme at 10 s, final hit at 26 s).
cut around-warsaw-beta-30s.mp4 \
	"atrim=0.48:42,asetpts=PTS-STARTPTS,asplit[m1][m2];[m1]atrim=0:4,asetpts=PTS-STARTPTS[ma];[m2]atrim=10:36.1,asetpts=PTS-STARTPTS[mb];[ma][mb]acrossfade=d=0.03:c1=tri:c2=tri,atrim=0:30,afade=t=out:st=28.8:d=1.2" \
	old_town:0.5:1.5:2 kebab:1:2.5 pullover:2:2 vistula:1:2 palace_time:3:2:4 \
	heli_dive:0.5:3:1.5 chase:1:3 club:5.5:2 boat:3.5:2 drag:3:3 heli_play:1:1.5 \
	palace_time:11:1.5 card:0.3:4.2
