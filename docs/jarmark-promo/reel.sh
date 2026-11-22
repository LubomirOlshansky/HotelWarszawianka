#!/bin/zsh
# One ~18 s Jarmark reel from the graded takes in DIR (tools/jarmark_shots.sh): hard cuts, 1080x1920
# 30 fps, silent (F cuts his own with music). Missing takes are skipped.
#   docs/jarmark-promo/reel.sh DIR
emulate -L zsh
DIR=${1:?usage: reel.sh DIR}
# name:start:length
picks=(m10-flyover-long-slow:0.5:2.5 q02-tree-orbit-quick:0.3:2 s06-aisle:0.5:2 m07-sign-push-slow:1:2
	q03-tower-orbit-quick:0.3:2 m04-kurant-orbit-slow:1:2 q01-aisle-pan-quick:0.3:1.8 m20-palace-reveal-slow:0.5:3.5)
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
	-colorspace bt709 -color_primaries bt709 -color_trc bt709 -movflags +faststart -an $DIR/jarmark-reel.mp4
rm -f $DIR/.reel-*.mp4 $list
print "reel: $DIR/jarmark-reel.mp4"
