#!/bin/zsh
# Racer AI step 5 (docs/design/race-ai.md 5.4): find the race links and prove them with the
# player's own car. Runs tools/race_links.py (the yards, car parks and alleys a racer can take,
# from the committed map, into game/data/race_links.json), then game/tools/check_lane_drive.gd
# --links in the prebuilt city (the car drives every link along the very curve a rival takes) and
# gives each link that passed its proof. A rival is handed only a proven link (race_cuts.gd).
# Step 5b (race-ai.md 5.5): the same for the wrong-way hops (kind "wrong": one block of a small
# one-way street, driven against its direction).
#   tools/race_links.sh             find and prove (the prebuilt city must be there:
#                                   tools/setup_map.sh; about a minute a link on the cloud's CPU)
#   tools/race_links.sh --runtime   prove in the runtime city instead (the sectors built from their files)
#   tools/race_links.sh --only=ID   prove only the links whose route name contains ID
# Run it after a centrum.json re-bake (check_race_links.gd fails while a link has no proof).
emulate -L zsh
set -e
ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
city=(--prebuilt)
only=()
for a in "$@"; do
	case $a in
		--runtime) city=() ;;
		--only=*) only=($a) ;;
		*) print -r -- "usage: tools/race_links.sh [--runtime] [--only=ID]"; exit 2 ;;
	esac
done
mkdir -p $ROOT/build
python3 -I $ROOT/tools/race_links.py --svg=$ROOT/build/race_links.svg
proof=$ROOT/build/race_links_proof.json
rm -f $proof
# (check_lane_drive exits 1 when a link fails: that link just gets no proof.)
$GODOT --headless --path $ROOT/game --fixed-fps 60 --script res://tools/check_lane_drive.gd -- \
	--links --write=$proof $city $only | tee $ROOT/build/race_links_proof.log | grep -E '^(ok|FAIL|check_lane_drive)' || true
if [[ ! -f $proof ]]; then
	print -r -- "race_links: the proof drive wrote nothing (log: build/race_links_proof.log)"; exit 1
fi
python3 -I $ROOT/tools/race_links.py --proofs=$proof --svg=$ROOT/build/race_links.svg
