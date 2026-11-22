#!/bin/zsh
# One ~23 s Jarmark reel from the graded takes in DIR (tools/jarmark_shots.sh): hard cuts, 1080x1920
# 30 fps, silent (F cuts his own with music). Missing takes are skipped.
#   docs/jarmark-promo/reel.sh DIR
emulate -L zsh
DIR=${1:?usage: reel.sh DIR}
# name:start:length
picks=(p2-50-still-far-behind:0.3:2.5 p2-16-behind-orbit-l:0.5:3 p2-07-front-orbit-r:0.5:3 p2-35-top-zoomout:0.5:3 p2-21-behind-fly-to-palace:0.5:3
	p2-23-s155-orbit:0.5:3 p2-47-q-top-spin:0.2:2 p2-10-front-pullout:0.5:3.5)
list=$DIR/reel-list.txt
: > $list
i=0
for p in $picks; do
	n=${p%%:*} rest=${p#*:} ss=${rest%%:*} len=${rest#*:}
	[[ -s $DIR/$n.mp4 ]] || { print "reel: no $n, skipped"; continue; }
	i=$((i + 1))
	ffmpeg -v error -y -ss $ss -i $DIR/$n.mp4 -t $len -c:v libx264 -preset slow -crf 16 -r 30 -pix_fmt yuv420p -an $DIR/.reel-$i.mp4
	print "file '.reel-$i.mp4'" >> $list
done
ffmpeg -v error -y -f concat -safe 0 -i $list -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p \
	-colorspace bt709 -color_primaries bt709 -color_trc bt709 -movflags +faststart -an $DIR/jarmark-reel-2.mp4
rm -f $DIR/.reel-*.mp4 $list
print "reel: $DIR/jarmark-reel-2.mp4"
