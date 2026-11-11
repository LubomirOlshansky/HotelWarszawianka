#!/bin/zsh
# The beta trailer's takes (game/scripts/trailer.gd) in one command, for quick rounds of changes.
#
#   tools/trailer.sh live TAKE [game flags]      play the take in a window in real time, no recording
#   tools/trailer.sh preview TAKE [game flags]   960x540, High, no MSAA -> build/trailer/preview/TAKE.mp4
#   tools/trailer.sh final TAKE [game flags]     1920x1080, the trailer's best picture -> build/trailer/final/TAKE.mp4
#   tools/trailer.sh cut [preview|final]         docs/trailer/cut.sh on that folder -> build/trailer/<mode>/cut/
#
# TAKE: the scripted flyovers palace_time, heli_dive, old_town, card, drift_day, drift_night, and the
# gameplay takes (HUD on, the game's own jokes; --trailer=play): kebab, ride, pullover, boat,
# vistula, chase, roadblock, club, drag, heli_play. The second iteration (docs/trailer/cut-v2.sh):
# old_town_fly, skyline, time_lapse, heli_stadium, castle_night (flights), raid, kebab2, boat2, club2.
# The prebuilt city (sectors + index.res from bake_city.gd) is used when game/map/index.res exists.
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
typeset -a game=(--nosave)
typeset -a play=(--trailer=play --trailer-len=8)
case $name in
	drift_day) game+=(--radio=0 --nohud --trailer=palace_drift --time=day) ;;
	drift_night) game+=(--radio=0 --nohud --trailer=palace_drift --time=night) ;;
	palace_time|heli_dive|old_town|card) game+=(--radio=0 --nohud --trailer=$name) ;;
	# The second iteration (F 2026-11-11, docs/trailer/cut-v2.sh): wide landmark flights (the whole
	# city loaded: a wide view needs more sectors than the streamer keeps), and gameplay shots with a
	# curated HUD (one speech bubble, no radio, zoom or district cards) and the trailer's own camera.
	old_town_fly|skyline|time_lapse|heli_stadium|castle_night) game+=(--radio=0 --nohud --sectors=all --trailer=$name) ;;
	raid) game+=(--radio=0 --nohud --trailer=palace_drift --time=night) ;;
	kebab2) game+=(--trailer=play --trailer-len=11 --time=day --kebab=3 --autopilot
		--trailer-cam=50,0,-36,900,0.6 --trailer-hud=clean,toast --trailer-bubble=kebab) ;;
	boat2) game+=(--trailer=play --trailer-len=12 --boat-race=auto --trailer-boat=192 --time=day
		--trailer-cam=44,120,-32,2,0.3,-8,0 --trailer-hud=clean --trailer-clean --trailer-bubble=szymek) ;;
	club2) game+=(--trailer=play --trailer-len=8 --meet-at=meet --time=night --trailer-hold
		--trailer-look=-1031,186 --trailer-cam=34,100,-36,6,0 --trailer-hud=clean,toast,banner
		--trailer-clean --trailer-bubble=lena) ;;
	kebab) game+=($play --kebab=3 --autopilot --time=day
		"--trailer-say=Prawdziwa Warszawa. W wersji kieszonkowej.|The real Warsaw, pocket-sized.") ;;
	ride) game+=($play --ride=2 --autopilot --time=day) ;;
	pullover) game+=($play --pullover=kebab --time=day) ;;
	boat) game+=($play --boat-race=auto --time=day) ;;
	vistula) game+=($play --drive-into-water=1015,-85 --time=dusk) ;;
	chase) game+=($play --police=2 --police-auto=escape --time=night
		"--trailer-say=Dzień, noc i radiowóz na ogonie.|Day, night and a cop car on your tail.") ;;
	roadblock) game+=($play --police=3 --police-auto=escape --time=night) ;;
	club) game+=($play --meet-at=meet --time=night) ;;
	drag) game+=($play --meet-at=stage --time=night) ;;
	heli_play) game+=($play --heli --demo --at=1486,-611 --time=dusk) ;;
	*) print -r -- "tools/trailer.sh: unknown take $name"; exit 2 ;;
esac
[[ -f $ROOT/game/map/index.res ]] && game+=(--prebuilt)
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

# Movie Maker records at the project's window size and ignores --resolution, so a temporary
# game/override.cfg (gitignored) sets the size for this run and is removed when the script exits.
size=${engine[(r)*x*]}
if [[ -e $ROOT/game/override.cfg ]]; then
	print -r -- "tools/trailer.sh: game/override.cfg already exists; move it away first"
	exit 1
fi
trap 'rm -f -- "$ROOT/game/override.cfg"' EXIT INT TERM
print -r -- "[display]
window/size/viewport_width=${size%x*}
window/size/viewport_height=${size#*x}
window/size/window_width_override=${size%x*}
window/size/window_height_override=${size#*x}" > $ROOT/game/override.cfg

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
first_png=$(ls $frames | grep -E '[0-9]+\.png$' | head -1)
pattern=$(print -r -- $first_png | sed -E 's/[0-9]+\.png$//')
digits=$(print -r -- $first_png | sed -E 's/^[^0-9]*([0-9]+)\.png$/\1/' | tr -d '\n' | wc -c | tr -d ' ')
ffmpeg -v error -y -framerate 60 -start_number $first -i "$frames/${pattern}%0${digits}d.png" \
	-frames:v $((last - first)) -c:v libx264 -crf $([[ $mode == final ]] && echo 16 || echo 23) \
	-pix_fmt yuv420p $out/$name.mp4
rm -rf $frames
print -r -- "$out/$name.mp4 ($((last - first)) frames, $(( $(date +%s) - start )) s)"
