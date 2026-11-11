#!/bin/bash
# The beta trailer's takes rendered in a Linux cloud container (headless Godot 4.7.2, Xvfb, Mesa's
# lavapipe software Vulkan, Movie Maker PNGs, then ffmpeg). The Mac's tools/trailer.sh does the same
# with Metal; this one runs takes side by side, each in its own copy of the project (Movie Maker
# records at the project's window size, so each copy gets its own override.cfg).
#
#   tools/trailer_cloud.sh NAME WxH FPS AA game flags...   -> build/trailer/cloud/NAME.mp4
#
# FPS: the capture's fixed frame rate (a flight the cut plays at 2.5x needs only 12). AA: the
# trailer's MSAA (0 for dusk and night: llvmpipe draws them empty with MSAA on). The flags after AA
# go to the game (--trailer=..., docs/trailer/README.md). Every run passes --nosave and --prebuilt
# (run tools/setup_map.sh first); SECTORS="--sectors=all" (the default) loads the whole city for wide
# views, about 5 GB a process: keep to two at once on a 16 GB machine, three without it.
# Example: tools/trailer_cloud.sh time_lapse 1920x1080 11 0 --nohud --trailer=time_lapse
set -u
name=$1; size=$2; fps=$3; aa=$4; shift 4
root=$(cd "$(dirname "$0")/.." && pwd)
out=$root/build/trailer/cloud
work=$out/work/$name
rm -rf "$work"; mkdir -p "$work/game" "$out"
(cd "$root/game" && tar cf - --exclude=./map --exclude=./override.cfg --exclude=./.godot .) | tar xf - -C "$work/game"
ln -s "$root/game/map" "$work/game/map"
cp -a "$root/game/.godot" "$work/game/.godot"
printf "[display]\nwindow/size/viewport_width=%s\nwindow/size/viewport_height=%s\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n" \
	"${size%x*}" "${size#*x}" "${size%x*}" "${size#*x}" > "$work/game/override.cfg"
timeout 3600 xvfb-run -a -s "-screen 0 ${size}x24" "${GODOT:-godot}" --path "$work/game" --resolution "$size" \
	--fixed-fps "$fps" --write-movie "$work/f.png" -- --nosave --prebuilt --radio=0 ${SECTORS---sectors=all} \
	--trailer-aa="$aa" "$@" > "$work/log" 2>&1
first=$(sed -nE 's/^trailer: .* starts at frame ([0-9]+).*/\1/p' "$work/log" | head -1)
last=$(sed -nE 's/^trailer: .* done at frame ([0-9]+).*/\1/p' "$work/log" | head -1)
if [[ -z $first || -z $last ]]; then
	echo "$name: did not finish (log: $work/log)"; tail -5 "$work/log"; exit 1
fi
png=$(ls "$work" | grep -E '^f[0-9]+\.png$' | head -1)
digits=$(echo -n "${png#f}" | sed 's/\.png//' | wc -c)
ffmpeg -v error -y -framerate "$fps" -start_number "$first" -i "$work/f%0${digits}d.png" -frames:v $((last - first)) \
	-c:v libx264 -crf 14 -pix_fmt yuv420p "$out/$name.mp4"
rm -f "$work"/f*.png
echo "$name: $out/$name.mp4 ($((last - first)) frames)"
