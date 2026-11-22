#!/bin/zsh
# The Jarmark promo shot batch (F 2026-11-22): every row of docs/jarmark-promo/shots.tsv as a
# 1080x1920 30 fps take with the trailer look on the runtime city, graded (grade D) into OUT, a
# contact sheet, and one reel cut from the picks. Promo branch only.
#
#   tools/jarmark_shots.sh OUT [FIRST_ROW_NAME]
#
# A take that fails clip.sh's freeze guard is retried once. Done takes are skipped on a rerun.
emulate -L zsh
setopt pipe_fail
ROOT=${0:A:h:h}
OUT=${1:?usage: tools/jarmark_shots.sh OUT [FROM]}
FROM=${2:-}
mkdir -p $OUT
GRADE="eq=saturation=0.95,curves=all='0/0.035 0.5/0.5 0.85/0.80 1/0.90',format=yuv420p"
started=$([[ -z $FROM ]] && echo 1 || echo 0)
grep -v '^#' $ROOT/docs/jarmark-promo/shots.tsv | while IFS=$'\t' read -r name secs cam yaw pitch size move; do
	[[ $started == 0 && $name != $FROM ]] && continue
	started=1
	[[ -s $OUT/$name.mp4 ]] && { print "skip $name (done)"; continue; }
	typeset -a flags=(--cam=$cam --yaw=$yaw --pitch=$pitch --size=$size --trailer --quality=experimental
		--lines=1920 --game-clock --date=20261121 --clock=20:30 --nohud --no-touch --no-ghost --promo-dress=jarmark)
	[[ -n $move ]] && flags+=(--cam-move=$move)
	for try in 1 2; do
		if CLIP_RUNTIME=1 $ROOT/tools/clip.sh $name 1080x1920 $secs --skip=8 -- $flags; then
			ffmpeg -v error -y -i $ROOT/build/clips/$name.mp4 -vf "$GRADE" -c:v libx264 -preset slow -crf 16 \
				-colorspace bt709 -color_primaries bt709 -color_trc bt709 -movflags +faststart -an $OUT/$name.mp4
			rm -rf $ROOT/build/clips/$name.frames
			print "ok $name"
			break
		fi
		print "FAILED $name (try $try)"
	done
done
