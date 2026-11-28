#!/usr/bin/env bash
# One finished video take from a Promo Mode COPY (skill: promo-video). It turns the phone's flag line
# into a tools/clip.sh run with every quality setting built in, so a take never loses the look again.
#
#   tools/promo_clip.sh NAME "COPY FLAGS" [options] [-- EXTRA GAME FLAGS]
#
#   NAME        the take's name: build/clips/NAME.mp4 (+ NAME-sheet.png, NAME.log, NAME.still.png)
#   COPY FLAGS  the line Promo Mode's COPY button put on the clipboard, in quotes
#               (--cam=X,Y,Z --yaw= --pitch= --size= --game-clock --clock= --date= [--weather=rain])
#
#   --out=WxH        clip size: 1080x1920 (default, Reels/TikTok/Shorts), 1920x1080, 1080x1350
#   --secs=N         length in whole seconds (default 3)
#   --fps=N          frames per second (default 60: smooth motion; the cut re-times to 30 for Reels)
#   --view-scale=K   multiply COPY's --size by K (default: 0.818 for a 9:16 clip; 1 for 16:9 and 4:5)
#   --wider=PCT      F's note "wider": --size grows by PCT percent (--wider=15); --closer=PCT shrinks it
#   --at=X,Z         where the car stands. REQUIRED when the focus is over water or off the roads
#                    (the car spawns under the camera, falls in the river and is towed, and the shot moves)
#   --prebuilt       default; --runtime turns it off (the runtime city build, for a map change not yet baked)
#   --still          render the 1-second check still only (half size, NAME.still.png), not the take
#   --preview        a half-size High-quality take for framing rounds
#   --dry            print the clip.sh command and stop
#
# Built in on every take (F, 2026-11-21, teasers 4 and 5): --governor=off (otherwise the frame
# governor steps down and the view goes top-down and zoomed), --lines=<video height> (a tall frame
# without it is blown-up blocks), --quality=ultra, --nohud --no-touch --no-ghost, --sectors=all,
# --prebuilt, silent, the window always on top (clip.sh). Promo VIEW is the whole phone screen
# height, hence the 0.818 (= 2347/2868) on a 1080x1920 clip.
#
# Extras go after `--`: --people=N, --promo-at=X,Z[,T] (trams and a bus), --scoot-gang=X,Z[,T[,DIR]],
# --promo-heli=X,Z,TX,TZ,ALT[,SHARE], --season=summer, --weather=rain, --grade=golden ...
#
# Example (teaser 4, the palm):
#   tools/promo_clip.sh palm "--cam=-178.5,260.8,0 --yaw=237.2 --pitch=-27.6 --size=117.3 --game-clock --clock=15:20 --date=20261120" \
#       --secs=3 --at=-170,250 -- --season=summer --promo-at=-170,250 --scoot-gang=-190,240
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
name=${1:?usage: tools/promo_clip.sh NAME "COPY FLAGS" [options] [-- EXTRA GAME FLAGS]}
copy=${2:?COPY FLAGS (the Promo Mode COPY line, in quotes)}
shift 2

out=1080x1920 secs=3 fps=60 scale="" wider=0 at="" still=0 preview=0 dry=0 prebuilt=1
extra=()
while (($#)); do
	case $1 in
		--out=*) out=${1#*=} ;;
		--secs=*) secs=${1#*=} ;;
		--fps=*) fps=${1#*=} ;;
		--view-scale=*) scale=${1#*=} ;;
		--wider=*) wider=${1#*=} ;;
		--closer=*) wider=-${1#*=} ;;
		--at=*) at=${1#*=} ;;
		--runtime) prebuilt=0 ;;
		--prebuilt) prebuilt=1 ;;
		--still) still=1 ;;
		--preview) preview=1 ;;
		--dry) dry=1 ;;
		--) shift; extra=("$@"); break ;;
		*) echo "tools/promo_clip.sh: unknown option $1" >&2; exit 2 ;;
	esac
	shift
done

w=${out%x*} h=${out#*x}
if [[ -z $scale ]]; then
	# 9:16 (and anything taller than wide): the Promo VIEW is the whole portrait phone screen
	# (2868 px), the clip crops it to 2347 px of it. Landscape and 4:5 clips: take VIEW as is.
	if ((h * 9 >= w * 16)); then scale=0.818; else scale=1; fi
fi

# Pull the frame out of the COPY line: --size scaled, everything else passed through.
game=()
size=""
for tok in $copy; do
	case $tok in
		--size=*) size=${tok#*=} ;;
		--cam=*|--yaw=*|--pitch=*|--game-clock|--clock=*|--date=*|--weather=*) game+=("$tok") ;;
		--at=*) [[ -z $at ]] && at=${tok#*=} ;;
		*) echo "tools/promo_clip.sh: ignoring unknown COPY token '$tok'" >&2 ;;
	esac
done
[[ -n $size ]] || { echo "tools/promo_clip.sh: the COPY line has no --size=" >&2; exit 2; }
game=("--size=$(awk -v s="$size" -v k="$scale" -v w="$wider" 'BEGIN { printf "%.1f", s * k * (1 + w / 100) }')" "${game[@]}")
[[ " ${game[*]} " == *" --cam="* ]] || { echo "tools/promo_clip.sh: the COPY line has no --cam=" >&2; exit 2; }

if [[ -z $at ]]; then
	echo "tools/promo_clip.sh: note: no --at=; if the --cam focus is over water the car drops in the river" >&2
	echo "  and is towed (the shot moves). Pass --at=X,Z on a road nearby." >&2
else
	game+=("--at=$at")
fi

# Quality, always. --lines is the video height (half for --preview/--still, which clip.sh halves).
q=(--governor=off --lines="$h" --quality=ultra --nohud --no-touch --no-ghost --sectors=all)
((prebuilt)) && q+=(--prebuilt)
((${#extra[@]})) && game+=("${extra[@]}")

cmd=(tools/clip.sh "$name" "$out" "$secs" --fps="$fps")
if ((still)); then
	# One second, half size: a look at the framing in about a minute. Take its sheet's middle frame.
	cmd=(tools/clip.sh "$name-still" "$out" 1 --fps=30 --preview)
	q=("${q[@]/--lines=$h/--lines=$((h / 2))}")
elif ((preview)); then
	cmd+=(--preview)
	q=("${q[@]/--lines=$h/--lines=$((h / 2))}")
fi
cmd+=(-- "${game[@]}" "${q[@]}")

printf '%q ' "${cmd[@]}"; echo
((dry)) && exit 0
cd "$ROOT"
"${cmd[@]}"
if ((still)); then
	# The preview's contact sheet is 8 frames; the check still is its 5th, cut out whole.
	if [[ -f build/clips/$name-still.mp4 ]]; then
		ffmpeg -v error -y -ss 0.5 -i "build/clips/$name-still.mp4" -frames:v 1 "build/clips/$name.still.png"
		echo "build/clips/$name.still.png"
	fi
fi
