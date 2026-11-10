#!/bin/zsh
# The race bench (docs/design/race-ai.md, "How we test it"): rival races on the committed map with
# the real traffic and the game's own race code, headless, without the city
# (game/tools/check_race_bench.gd; the races and the pass marks are in game/tools/race_bench.gd).
#   tools/race_bench.sh                  the full matrix (about 4 minutes): a line a race, the pass
#                                        marks, every number in build/race_bench/full.json
#   tools/race_bench.sh --quick          the quick matrix (what tools/verify.sh and CI run, 30 s)
#   tools/race_bench.sh --out=before     name the run (build/race_bench/before.json and .log)
#   tools/race_bench.sh --against=FILE   show an earlier run's numbers beside this run's (a json this
#                                        script wrote: run --out=before on main, then this on the branch)
#   tools/race_bench.sh --only=TEXT [--trace]   only the races whose id contains TEXT, with what the
#                                        rival does once a second (--list prints the ids); its lines
#                                        go to build/race_bench/part.log and no json is written
#   tools/race_bench.sh --write          run both matrices and record their marks in
#                                        game/data/race_bench.json (when a change moves a mark on purpose)
# Exit code: the check's (0 when no mark recorded as a pass fails), 2 for a usage error.
emulate -L zsh
setopt pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
out=$ROOT/build/race_bench
matrix=full; name=; write=0; partial=0; rest=()
for a in "$@"; do
	case $a in
		--quick) matrix=quick ;;
		--write) write=1 ;;
		--out=*) name=${a#--out=} ;;
		--against=*) rest+=(--against=${${a#--against=}:A}) ;;
		--only=*|--list) rest+=($a); partial=1 ;;
		--trace) rest+=($a) ;;
		*) print -r -- "usage: tools/race_bench.sh [--quick] [--out=NAME] [--against=FILE] [--only=TEXT] [--trace] [--list] [--write]"; exit 2 ;;
	esac
done
if ! command -v $GODOT > /dev/null; then
	print -r -- "'$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
fi
mkdir -p $out || exit 1

# run MATRIX NAME FLAGS...: one run of the check; its lines also go to build/race_bench/NAME.log.
run() {
	local m=$1 n=$2; shift 2
	local flags=($rest "$@")
	[[ $m == full ]] && flags+=(--full)
	# A part of the matrix is not a run to keep the numbers of: no json, and its own log, so a
	# look at one race does not write over the last whole run's lines.
	if (( partial )); then n=part; else flags+=(--json=$out/$n.json); fi
	( cd $ROOT/game && $GODOT --headless --path . --script res://tools/check_race_bench.gd -- $flags ) 2>&1 | tee $out/$n.log
}

if (( write )); then
	run quick quick --write && run full full --write
else
	run $matrix ${name:-$matrix}
fi
