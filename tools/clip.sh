#!/bin/zsh
# One game clip at any size and frame rate (portrait for Reels, landscape for trailers), recorded
# offline with Godot's Movie Maker so even --quality=experimental never stutters. Skill: shoot-video.
#
#   tools/clip.sh NAME WxH SECONDS [--fps=30] [--skip=4] [--preview] -- GAME FLAGS...
#
#   NAME      the clip's name: build/clips/NAME.mp4 (+ NAME.log, NAME-sheet.png)
#   WxH       1080x1920 for Reels/Shorts/TikTok, 1920x1080 for a trailer, 1080x1350 for a feed post
#   SECONDS   the clip's length after the skip
#   --skip=S  seconds dropped from the head while the city streams in (default 4)
#   --preview half size, --quality=high, MSAA off: about 4x faster, for framing rounds
#
# Every run gets --nosave and --notitle and quits by itself (--quit-after). Movie Maker records at the
# project's window size and ignores --resolution, so a temporary game/override.cfg (gitignored) sets
# the size and is removed when the script exits. The master is H.264 CRF 14, yuv420p, no audio; the
# cut (tools/reel_cut.sh or docs/teaser/cut.sh) does the final encode. NAME-sheet.png is a contact
# sheet of 8 frames: look at it before cutting.
#
# Example (the teaser's bridge shot):
#   tools/clip.sh bridge 1080x1920 3 -- --at=905,-760 --heading=70 --demo --time=dusk \
#       --yaw=200 --pitch=-30 --size=70 --nohud --no-touch --quality=experimental
emulate -L zsh
setopt err_exit pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
name=${1:?usage: tools/clip.sh NAME WxH SECONDS [--fps=30] [--skip=4] [--preview] -- GAME FLAGS}
size=${2:?WxH}
secs=${3:?SECONDS}
shift 3
fps=30 skip=4 preview=0
while (( $# )) && [[ $1 != -- ]]; do
	case $1 in
		--fps=*) fps=${1#*=} ;;
		--skip=*) skip=${1#*=} ;;
		--preview) preview=1 ;;
		*) print -r -- "tools/clip.sh: unknown option $1"; exit 2 ;;
	esac
	shift
done
[[ ${1:-} == -- ]] && shift
typeset -a game=(--nosave --notitle "$@")
w=${size%x*} h=${size#*x}
if (( preview )); then
	w=$((w / 2)) h=$((h / 2))
	game+=(--quality=high)
fi
[[ -f $ROOT/game/map/index.res && ${game[(I)--prebuilt]} -eq 0 ]] && game+=(--prebuilt)

if [[ -e $ROOT/game/override.cfg ]]; then
	print -r -- "tools/clip.sh: game/override.cfg already exists; move it away first"
	exit 1
fi
trap 'rm -f -- "$ROOT/game/override.cfg"' EXIT INT TERM
print -r -- "[display]
window/size/viewport_width=$w
window/size/viewport_height=$h
window/size/window_width_override=$w
window/size/window_height_override=$h
window/size/always_on_top=true" > $ROOT/game/override.cfg
# always_on_top (2026-11-19, teaser 2): macOS skips drawing a hidden window, so a clip shot behind
# another full-screen app wrote the same frame for ~45 frames at a time (Movie Maker repeats it).

out=$ROOT/build/clips
frames=$out/$name.frames
rm -rf $frames
mkdir -p $frames
total=$(( (skip + secs) * fps + 2 ))
total=${total%.*}
start=$(date +%s)
# perl alarm: macOS has no timeout(1). 20 min is far more than any clip needs.
perl -e 'alarm shift; exec @ARGV' 1200 $GODOT --path $ROOT/game --fixed-fps $fps --quit-after $total \
	--write-movie $frames/f.png -- $game > $out/$name.log 2>&1 || true
first_png=$(ls $frames | grep -E '[0-9]+\.png$' | head -1)
if [[ -z $first_png ]]; then
	print -r -- "tools/clip.sh: $name wrote no frames (log: $out/$name.log)"
	exit 1
fi
pattern=${first_png%%[0-9]*.png}
digits=$(( ${#first_png} - ${#pattern} - 4 ))
first=$(( skip * fps ))
first=${first%.*}
ffmpeg -v error -y -framerate $fps -start_number $first -i "$frames/${pattern}%0${digits}d.png" \
	-frames:v $(( ${secs%.*} * fps )) -c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p -an $out/$name.mp4
ffmpeg -v error -y -i $out/$name.mp4 -vf "fps=8/${secs},scale=-2:480,tile=8x1" -frames:v 1 $out/$name-sheet.png
rm -rf $frames
print -r -- "$out/$name.mp4 (${w}x${h}, ${secs} s at $fps fps, $(( $(date +%s) - start )) s to render)"
