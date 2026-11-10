#!/bin/zsh
# The beta trailer's takes (game/scripts/trailer.gd) in one command, for quick rounds of changes.
#
#   tools/trailer.sh live TAKE [game flags]      play the take in a window in real time, no recording
#   tools/trailer.sh preview TAKE [game flags]   960x540, High, no MSAA -> build/trailer/preview/TAKE.mp4
#   tools/trailer.sh final TAKE [game flags]     1920x1080, the trailer's best picture -> build/trailer/final/TAKE.mp4
#   tools/trailer.sh cut [preview|final]         docs/trailer/cut.sh on that folder -> build/trailer/<mode>/cut/
#
# TAKE: palace_time, heli_dive, old_town, card, drift_day (palace_drift by day), drift_night.
# The prebuilt city is used when game/map/city.scn exists (no 3 min runtime build before each take).
# Each take quits by itself; the loading frames before "trailer: TAKE starts at frame N" are cut.
# Needs ffmpeg for preview, final and cut. Every run passes --nosave.

emulate -L zsh
setopt err_exit pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
mode=${1:?usage: tools/trailer.sh live|preview|final|cut TAKE [flags]}
shift

if [[ $mode == cut ]]; then
	from=${1:-final}
	$ROOT/docs/trailer/cut.sh $ROOT/build/trailer/$from $ROOT/build/trailer/$from/cut
	exit 0
fi

name=${1:?which take}
shift
typeset -a game=(--nosave --radio=0 --nohud)
case $name in
	drift_day) game+=(--trailer=palace_drift --time=day) ;;
	drift_night) game+=(--trailer=palace_drift --time=night) ;;
	palace_time|heli_dive|old_town|card) game+=(--trailer=$name) ;;
	*) print -r -- "tools/trailer.sh: unknown take $name"; exit 2 ;;
esac
[[ -f $ROOT/game/map/city.scn ]] && game+=(--prebuilt)
game+=("$@")

typeset -a engine
case $mode in
	live) engine=(--resolution 1280x720 --quit-after 20000) ;;
	preview) engine=(--resolution 960x540 --fixed-fps 60 --quit-after 20000); game+=(--quality=high --lines=540 --trailer-aa=0) ;;
	final) engine=(--resolution 1920x1080 --fixed-fps 60 --quit-after 20000) ;;
	*) print -r -- "tools/trailer.sh: mode is live, preview, final or cut"; exit 2 ;;
esac

if [[ $mode == live ]]; then
	$GODOT --path $ROOT/game $engine -- $game
	exit 0
fi

out=$ROOT/build/trailer/$mode
frames=$out/$name.frames
rm -rf $frames
mkdir -p $frames
log=$out/$name.log
start=$(date +%s)
$GODOT --path $ROOT/game $engine --write-movie $frames/f.png -- $game > $log 2>&1 || true
first=$(sed -nE 's/^trailer: .* starts at frame ([0-9]+).*/\1/p' $log | head -1)
last=$(sed -nE 's/^trailer: .* done at frame ([0-9]+).*/\1/p' $log | head -1)
if [[ -z $first || -z $last ]]; then
	print -r -- "tools/trailer.sh: $name did not finish (log: $log)"
	exit 1
fi
pattern=$(ls $frames | head -1 | sed -E 's/[0-9]+\.png$//')
digits=$(ls $frames | head -1 | sed -E 's/^[^0-9]*([0-9]+)\.png$/\1/' | tr -d '\n' | wc -c | tr -d ' ')
ffmpeg -v error -y -framerate 60 -start_number $first -i "$frames/${pattern}%0${digits}d.png" \
	-frames:v $((last - first)) -c:v libx264 -crf $([[ $mode == final ]] && echo 16 || echo 23) \
	-pix_fmt yuv420p $out/$name.mp4
rm -rf $frames
print -r -- "$out/$name.mp4 ($((last - first)) frames, $(( $(date +%s) - start )) s)"
