#!/bin/zsh
# One game clip at any size and frame rate (portrait for Reels, landscape for trailers), recorded
# offline with Godot's Movie Maker so even --quality=experimental never stutters. Skill: shoot-video.
#
#   tools/clip.sh NAME WxH SECONDS [--fps=30] [--skip=4] [--preview] [--grade=d] [--retries=2] -- GAME FLAGS...
#
#   NAME      the clip's name: build/clips/NAME.mp4 (+ NAME.log, NAME-sheet.png)
#   WxH       1080x1920 for Reels/Shorts/TikTok, 1920x1080 for a trailer, 1080x1350 for a feed post
#   SECONDS   the clip's length after the skip
#   --skip=S  seconds dropped from the head while the city streams in (default 4)
#   --preview half size, --quality=high, MSAA off: about 4x faster, for framing rounds
#   --grade=d F's trailer grade D (2026-11-21) baked into the master: saturation 0.95, lifted blacks
#   --retries=N re-render a frozen take up to N more times (default 2): Experimental freezes at random
#
# Every run gets --nosave and --notitle and quits by itself (--quit-after). Movie Maker records at the
# project's window size and ignores --resolution, so a temporary game/override.cfg (gitignored) sets
# the size and is removed when the script exits. The master is H.264 CRF 14, yuv420p, no audio; the
# cut (tools/reel_cut.sh or docs/teaser/cut.sh) does the final encode. NAME-sheet.png is a contact
# sheet of 8 frames: look at it before cutting.
#
# Example (the teaser's bridge shot):
#   tools/clip.sh bridge 1080x1920 3 -- --at=905,-760 --heading=70 --demo --time=dusk \
#       --yaw=200 --pitch=-30 --size=70 --nohud --no-touch --quality=ultra --lines=1920
#
# Guards (2026-11-21, frozen palm takes): --governor=off is always added; the run is refused while
# another Godot runs; the Mac is kept awake (caffeinate); the clip FAILS (exit 1, frames and log
# kept) when frames are missing or Movie Maker repeated one picture for 1 s or more after the skip.
# Guards (2026-11-22, stadium re-shoot): the PNGs must be exactly WxH (a hand-made window of half the
# size rendered half-size frames), and a log line "governor: view back in" fails the take (the governor
# pulled the view in and the shot showed the wrong place). Never shoot by hand at 2160x3840: two of two
# such takes froze; shoot 1080x1920 (F, 2026-11-22).
emulate -L zsh
setopt err_exit pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
name=${1:?usage: tools/clip.sh NAME WxH SECONDS [--fps=30] [--skip=4] [--preview] -- GAME FLAGS}
size=${2:?WxH}
secs=${3:?SECONDS}
shift 3
fps=30 skip=4 preview=0 grade="" retries=2
while (( $# )) && [[ $1 != -- ]]; do
	case $1 in
		--fps=*) fps=${1#*=} ;;
		--skip=*) skip=${1#*=} ;;
		--preview) preview=1 ;;
		--grade=d) grade="eq=saturation=0.95,curves=all='0/0.035 0.5/0.5 0.85/0.80 1/0.90'," ;;
		--retries=*) retries=${1#*=} ;;
		*) print -r -- "tools/clip.sh: unknown option $1"; exit 2 ;;
	esac
	shift
done
[[ ${1:-} == -- ]] && shift
typeset -a game=(--nosave --notitle "$@")
(( ${game[(I)--governor=*]} )) || game+=(--governor=off)
if pgrep -if 'godot.*--write-movie' > /dev/null; then
	print -r -- "tools/clip.sh: another Godot is running (pgrep -ilf godot); one render at a time"
	exit 1
fi
w=${size%x*} h=${size#*x}
if (( preview )); then
	w=$((w / 2)) h=$((h / 2))
	game+=(--quality=high)
fi
# CLIP_RUNTIME=1 (Jarmark promo, 2026-11-22): the runtime city build, no --prebuilt (stale sectors).
[[ -z ${CLIP_RUNTIME:-} && -f $ROOT/game/map/index.res && ${game[(I)--prebuilt]} -eq 0 ]] && game+=(--prebuilt)

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
total=$(( (skip + secs) * fps + 2 ))
total=${total%.*}
start=$(date +%s)
mkdir -p $out
# One take: render, then check. Returns 0 for a good take, 1 for a broken one that a retry may fix.
take() {
rm -rf $frames
mkdir -p $frames
# perl alarm: macOS has no timeout(1). 20 min is far more than any clip needs.
caffeinate -dimsu perl -e 'alarm shift; exec @ARGV' ${CLIP_ALARM:-1200} $GODOT --path $ROOT/game --fixed-fps $fps --quit-after $total \
	--write-movie $frames/f.png -- $game > $out/$name.log 2>&1 || true
first_png=$(ls $frames | grep -E '[0-9]+\.png$' | head -1)
if [[ -z $first_png ]]; then
	print -r -- "tools/clip.sh: $name wrote no frames (log: $out/$name.log)"
	return 1
fi
# PNG width and height sit at bytes 16-23 of the file (IHDR).
pngsize=$(python3 -I -c 'import struct,sys; d=open(sys.argv[1],"rb").read(24); print("%dx%d" % struct.unpack(">II", d[16:24]))' $frames/$first_png)
if [[ $pngsize != ${w}x${h} ]]; then
	print -r -- "tools/clip.sh: $name FAILED: frames are $pngsize, not ${w}x${h} (window size wrong; frames kept in $frames)"
	return 2
fi
if grep -q 'governor: view back in' $out/$name.log; then
	print -r -- "tools/clip.sh: $name FAILED: the governor changed the view mid-take (log: $out/$name.log); pass --governor=off"
	return 2
fi
pattern=${first_png%%[0-9]*.png}
digits=$(( ${#first_png} - ${#pattern} - 4 ))
first=$(( skip * fps ))
first=${first%.*}
want=$(( first + ${secs%.*} * fps ))
got=$(ls $frames | grep -cE '[0-9]+\.png$' || true)
if (( got < want )); then
	print -r -- "tools/clip.sh: $name FAILED: $got frames, needs $want (crash or alarm? log: $out/$name.log, frames kept)"
	return 1
fi
# Movie Maker repeats a stale picture bit for bit when the 3D stops drawing; real frames never match.
run=$( { cd $frames && ls | grep -E '[0-9]+\.png$' | sort | sed -n "$(( first + 1 )),$(( want ))p" \
	| xargs md5 -q | uniq -c | sort -rn | awk 'NR == 1 {print $1}'; } || true )
run=${run:-0}
if (( run >= fps )); then
	print -r -- "tools/clip.sh: $name FAILED: one picture repeats for $run frames (frozen take; frames kept in $frames)"
	return 1
fi
return 0
}

try=0
while true; do
	take && break
	rc=$?
	(( rc == 1 && try < retries )) || exit 1
	try=$(( try + 1 ))
	print -r -- "tools/clip.sh: $name retry $try of $retries"
done
ffmpeg -v error -y -framerate $fps -start_number $first -i "$frames/${pattern}%0${digits}d.png" \
	-frames:v $(( ${secs%.*} * fps )) -vf "${grade}scale=out_color_matrix=bt709" -c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p \
	-colorspace bt709 -color_primaries bt709 -color_trc bt709 -an $out/$name.mp4
# A take can freeze at random (window not redrawn, two Godots at once): count the frames that move.
moving=$(ffmpeg -i $out/$name.mp4 -vf "mpdecimate=hi=256:lo=64:frac=0.1,showinfo" -f null - 2>&1 | grep -c "Parsed_showinfo.*pts_time" || true)
echo "clip: $name moving frames $moving of $(( ${secs%.*} * fps )), longest repeat $run, retries $try, $(grep -o 'quality: [^·]*' $out/$name.log | tail -1)"
grep -q 'back to Ultra' $out/$name.log && print -r -- "tools/clip.sh: WARNING $name dropped from Experimental to Ultra mid-take"
ffmpeg -v error -y -i $out/$name.mp4 -vf "fps=8/${secs},scale=-2:480,tile=8x1" -frames:v 1 $out/$name-sheet.png
rm -rf $frames
print -r -- "$out/$name.mp4 (${w}x${h}, ${secs} s at $fps fps, $(( $(date +%s) - start )) s to render)"
