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
#   tools/race_bench.sh --jobs=N         run the matrix in N parts side by side and judge them as one
#                                        run (the full matrix is 272 races: 15 minutes in one
#                                        go, 4 on four cores). The races come out the same; only
#                                        the json's timing fields (step_usec, wall_ms) are not to be
#                                        trusted with other parts running
#   tools/race_bench.sh --write          run both matrices and record their marks in
#                                        game/data/race_bench.json (when a change moves a mark on purpose)
# Exit code: the check's (0 when no mark recorded as a pass fails), 2 for a usage error.
emulate -L zsh
setopt pipe_fail
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
out=$ROOT/build/race_bench
matrix=full; name=; write=0; partial=0; jobs=1; rest=()
for a in "$@"; do
	case $a in
		--quick) matrix=quick ;;
		--write) write=1 ;;
		--out=*) name=${a#--out=} ;;
		--against=*) rest+=(--against=${${a#--against=}:A}) ;;
		--only=*|--list) rest+=($a); partial=1 ;;
		--trace) rest+=($a) ;;
		--jobs=<->) jobs=${a#--jobs=} ;;
		*) print -r -- "usage: tools/race_bench.sh [--quick] [--out=NAME] [--against=FILE] [--only=TEXT] [--trace] [--list] [--jobs=N] [--write]"; exit 2 ;;
	esac
done
if ! command -v $GODOT > /dev/null; then
	print -r -- "'$GODOT' not found (Godot 4.7.2; set GODOT=/path/to/godot)"; exit 1
fi
mkdir -p $out || exit 1
# A clone Godot has never opened: import first (as tools/verify.sh does), or the game's scripts
# do not load and no race runs.
if [[ ! -f $ROOT/game/.godot/global_script_class_cache.cfg ]]; then
	print -r -- "race_bench: importing the project first (no game/.godot yet)"
	$GODOT --headless --path $ROOT/game --import > /dev/null 2>&1
fi

# run MATRIX NAME FLAGS...: one run of the check; its lines also go to build/race_bench/NAME.log.
run() {
	local m=$1 n=$2; shift 2
	local flags=($rest "$@")
	[[ $m == full ]] && flags+=(--full)
	# A part of the matrix is not a run to keep the numbers of: no json, and its own log, so a
	# look at one race does not write over the last whole run's lines.
	if (( partial )); then n=part; else flags+=(--json=$out/$n.json); fi
	if (( jobs > 1 && ! partial )); then
		# In parts: each part's races to its own json and log, then one run of the check that
		# judges them all (the lines of the races first, part by part).
		local k pids=() files=() bad=0
		for (( k = 0; k < jobs; k++ )); do
			files+=($out/$n.part$k.json)
			( cd $ROOT/game && $GODOT --headless --path . --script res://tools/check_race_bench.gd -- ${flags:#--json=*} --part=$k/$jobs --json=$out/$n.part$k.json ) > $out/$n.part$k.log 2>&1 &
			pids+=($!)
		done
		for k in $pids; do wait $k || bad=1; done
		cat $out/$n.part<->.log > $out/$n.log
		grep -v '^check_race_bench: part ' $out/$n.log
		(( bad )) && { print -r -- "race_bench: a part did not run to its end (see $out/$n.part*.log)"; return 1 }
		( cd $ROOT/game && $GODOT --headless --path . --script res://tools/check_race_bench.gd -- $flags --merge=${(j:,:)files} ) 2>&1 | tee -a $out/$n.log
		local code=$pipestatus[1]
		rm -f $out/$n.part<->.json $out/$n.part<->.log
		return $code
	fi
	( cd $ROOT/game && $GODOT --headless --path . --script res://tools/check_race_bench.gd -- $flags ) 2>&1 | tee $out/$n.log
}

if (( write )); then
	run quick quick --write && run full full --write
else
	run $matrix ${name:-$matrix}
fi
