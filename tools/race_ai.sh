#!/bin/zsh
# Street races (docs/design/street-races.md, 2026-11-04): the race-AI runs. Each rival races the
# autopilot (an average player at --ghost-pace 1.8, a skilled one at --ghost-pace=racer) headless from the start
# spot, and the table shows who won, the time and the rival's racing line ("race ai: ..." from
# rivals.gd: top speed, skill share, effort range, seconds stopped, passes, the gap at the end; gap < 0: the
# rival finished that many metres ahead of the player).
#   tools/race_ai.sh [--pace=1.8,racer] [--rivals=1,2,3,4,5,6] [--jobs=2] [--logs=DIR]
# Each run plays up to 14000 frames (~4 min of play, 3-6 min of wall time in the cloud).
emulate -L zsh
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
paces=(1.8 racer); rivals=(1 2 3 4 5 6); jobs=2; logs=$ROOT/build/race_ai
for a in "$@"; do
	case $a in
		--pace=*) paces=(${(s:,:)${a#--pace=}}) ;;
		--rivals=*) rivals=(${(s:,:)${a#--rivals=}}) ;;
		--jobs=*) jobs=${a#--jobs=} ;;
		--logs=*) logs=${a#--logs=} ;;
		*) print -r -- "usage: tools/race_ai.sh [--pace=1.8,racer] [--rivals=1,...,6] [--jobs=2] [--logs=DIR]"; exit 2 ;;
	esac
done
mkdir -p $logs
run() {
	( cd $ROOT/game && $GODOT --headless --path . --fixed-fps 60 --quit-after 14000 -- --nosave --notitle \
		--race=$1 --autopilot --ghost-pace=$2 ) > $logs/race$1_pace$2.log 2>&1
}
n=0
for p in $paces; do
	for r in $rivals; do
		run $r $p &
		(( ++n % jobs == 0 )) && wait
	done
done
wait
print "rival · player pace · result · line"
for p in $paces; do
	for r in $rivals; do
		f=$logs/race${r}_pace$p.log
		res=$(grep -m1 -oE '^race (won|lost)' $f | sed 's/^race //')
		line=$(grep -m1 '^race ai:' $f | sed 's/^race ai: //')
		print -r -- "$r · $p · ${res:-none} · ${line:-no race line ($f)}"
	done
done
