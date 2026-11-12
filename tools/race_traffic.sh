#!/bin/zsh
# What the town's traffic costs a racer, measured and fitted (docs/design/race-ai.md 5; the
# planner's traffic delay, game/scripts/traffic.gd RACE_STUCK* and `race_delay`): three rivals
# drive ten courses on the race bench at Low, Normal and Busy traffic against the same streets on
# clear roads (game/tools/race_traffic.gd, headless, no city), then tools/race_traffic.py fits the
# delay's numbers to the streets and says how well the ones in traffic.gd still give a race's time.
# Run it when the way a racer meets the town's cars changes (a new pass, a new lane rule), and move
# the constants when the fit has.
#   tools/race_traffic.sh              four processes side by side, three draws of the town's
#                                      cars a level (about 8 minutes on four cores; build/race_traffic/)
#   tools/race_traffic.sh --parts=2    fewer processes (a small machine)
#   tools/race_traffic.sh --seeds=5    more draws a level
#   tools/race_traffic.sh --fit        only the fit, on the samples already in build/race_traffic/
# Exit code: the fit's (0), 1 when a sampler failed, 2 for a usage error.
emulate -L zsh
setopt pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
out=$ROOT/build/race_traffic
parts=4; seeds=3; fit_only=0
for a in "$@"; do
	case $a in
		--parts=*) parts=${a#--parts=} ;;
		--seeds=*) seeds=${a#--seeds=} ;;
		--fit) fit_only=1 ;;
		*) print -r -- "usage: tools/race_traffic.sh [--parts=4] [--seeds=3] [--fit]"; exit 2 ;;
	esac
done
if [[ $parts != <1-64> || $seeds != <1-99> ]]; then
	print -r -- "usage: tools/race_traffic.sh [--parts=4] [--seeds=3] [--fit]"; exit 2
fi
mkdir -p $out || exit 1
if (( ! fit_only )); then
	if ! command -v $GODOT > /dev/null; then
		print -r -- "'$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
	fi
	# A clone Godot has never opened: import first (as tools/race_bench.sh does).
	if [[ ! -f $ROOT/game/.godot/global_script_class_cache.cfg ]]; then
		print -r -- "race_traffic: importing the project first (no game/.godot yet)"
		$GODOT --headless --path $ROOT/game --import > /dev/null 2>&1
	fi
	rm -f $out/samples_*.csv(N) $out/samples_*.log(N)
	pids=()
	for k in {0..$((parts - 1))}; do
		( cd $ROOT/game && $GODOT --headless --path . --script res://tools/race_traffic.gd -- \
				--part=$k/$parts --seeds=$seeds --out=$out/samples_$k.csv ) > $out/samples_$k.log 2>&1 &
		pids+=($!)
	done
	failed=0
	for pid in $pids; do
		wait $pid || failed=1
	done
	grep -h "^race_traffic:" $out/samples_*.log
	if (( failed )); then
		print -r -- "race_traffic: a sampler failed (see build/race_traffic/samples_*.log)"; exit 1
	fi
fi
python3 -I $ROOT/tools/race_traffic.py $out | tee $out/fit.log
