#!/usr/bin/env bash
# Before/after comparison sheets for F (skill: promo-video). For every PNG that exists in both
# folders, one image with BEFORE on the left and AFTER on the right (same camera, same size).
#
#   tools/promo_sheet.sh BEFORE_DIR AFTER_DIR [OUT_DIR]      (OUT_DIR default: AFTER_DIR/../sheets)
#
# The stills come from the same flags run twice, once on the old commit and once on the new:
#   godot --path game --resolution 1080x1920 -- --nosave --prebuilt --sectors=all --quality=ultra --nohud \
#       --governor=off --at=X,Z --shots=40 --out=DIR --cams="name:x,y,z,yaw,pitch,size+name2:..."
# Always keep --at= (a camera over water drops the car in the river) and re-shoot "before" with the
# SAME camera when the camera had to change.
set -euo pipefail
before=${1:?BEFORE_DIR}; after=${2:?AFTER_DIR}
out=${3:-$after/../sheets}
mkdir -p "$out"
n=0
for f in "$after"/*.png; do
	b=$(basename "$f")
	[[ -f $before/$b ]] || { echo "promo_sheet: no before for $b, skipped" >&2; continue; }
	ffmpeg -v error -y -i "$before/$b" -i "$f" -filter_complex \
		"[0:v]drawtext=text='BEFORE':x=24:y=24:fontsize=48:fontcolor=white:box=1:boxcolor=black@0.6[a];[1:v]drawtext=text='AFTER':x=24:y=24:fontsize=48:fontcolor=white:box=1:boxcolor=black@0.6[b];[a][b]hstack=inputs=2" \
		"$out/sheet-${b%.png}.png" 2>/dev/null || \
	ffmpeg -v error -y -i "$before/$b" -i "$f" -filter_complex hstack=inputs=2 "$out/sheet-${b%.png}.png"
	echo "$out/sheet-${b%.png}.png"; n=$((n + 1))
done
((n)) || { echo "promo_sheet: no matching PNG names in both folders" >&2; exit 1; }
