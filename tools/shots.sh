#!/bin/zsh
# A standard set of screenshots at a phone's size, for the screenshot-review skill and the
# art director. Each shot is a separate run of the game (with a renderer, so a window opens),
# with --nosave, taken at frame 240 after the city is built (4 s of play at --fixed-fps 60),
# after which the game quits by itself.
#
#   tools/shots.sh                     the core set at 2532x1170 into shots/review_<time>/
#   tools/shots.sh --set=first         landmarks 0.3: palace, rotunda, tarasy alone, flat and silhouette
#   tools/shots.sh --set=quick         spawn by day (runtime city) + by night (prebuilt city)
#   tools/shots.sh --set=river_night,palace_day   just those (--list prints the names)
#   tools/shots.sh --size=2868x1320    another phone (default 2532x1170, a 6.1" iPhone;
#                                      2868x1320 is a 6.9" Pro Max)
#   tools/shots.sh --out=DIR --tag=after   where, and a suffix on each name (before / after)
#   tools/shots.sh --set=spawn_day -- --style=2 --quality=low   extra game flags for every shot
#   tools/shots.sh --set=roads         the road spots in tools/road_spots.txt (loop 3a): frame 90,
#                                      --no-traffic --fixed --size=70
#   tools/shots.sh --game=DIR          render another copy of the game (a before copy)
#
# Prints one line per shot (the PNG's path, or MISSING with the log's last error).

emulate -L zsh
zmodload zsh/datetime

ROOT=${0:A:h:h}
GODOT=${GODOT:-godot}
FRAME=240

# name -> game flags. Spots: the spawn on Marszałkowska by the glass tower east of Plac
# Defilad, Marszałkowska looking south, the Palace of Culture from the north-west, the river
# by Most Poniatowskiego, Rondo Dmowskiego.
typeset -A SHOT
FIRST=()
SHOT[spawn_day]="--time=day"
SHOT[spawn_night_prebuilt]="--prebuilt --time=night"
SHOT[defilad_pavilion]="--at=-950,205 --heading=160 --time=day"
SHOT[marszalkowska_day]="--at=-1113.2,-263.4 --heading=160 --time=day"
SHOT[palace_day]="--at=-1290,170 --heading=135 --time=day"
SHOT[river_day]="--at=1135.7,-198.1 --heading=72 --time=day"
SHOT[river_night]="--at=1135.7,-198.1 --heading=72 --time=night"
SHOT[rondo_rain_night]="--at=-806.3,446.4 --heading=335 --weather=rain --time=night"
SHOT[heli_day]="--heli --time=day"
SHOT[settings_panel]="--settings"
SHOT[classic_controls]="--controls=classic --pedal=gas"
# Landmarks 0.3 (the `first` set, model-from-photos skill section 5): the first scene's three
# heroes (and the Museum of Modern Art, first-scene item 1) alone on a plain background (--solo, DEVELOPMENT.md flags), unlit in their own colours
# (flat) and as a silhouette (sil), from the north-west like palace_day. Runtime city path only.
for sk in "palace -1290,170 150" "rotunda -808,378 45" "tarasy -1495,420 160" "msn -1022,100 70" "centralna -1440,560 180" "stadium 1480,-605 360" "kopernik 316,-866 150" "buw 50,-930 190"; do
	fk=(${=sk})  # not `set --`: that would eat the script's own arguments
	for lk in flat sil; do
		SHOT[first_${fk[1]}_$lk]="--at=${fk[2]} --heading=135 --time=day --nohud --size=${fk[3]} --solo=${fk[1]} --solo-look=$lk"
		FIRST+=(first_${fk[1]}_$lk)
	done
done
# Złote Tarasy and Złota 44 (detail pass, 2026-11-26): from the helicopter, the station side and the Złota side.
SHOT[tarasy_heli_day]="--heli --at=-1440,545 --heading=330 --time=day --nohud"
SHOT[tarasy_heli_night]="--heli --at=-1440,545 --heading=330 --time=night --nohud"
SHOT[zlota44_heli_day]="--heli --at=-1400,350 --heading=290 --time=day --nohud"
CORE=(spawn_day spawn_night_prebuilt marszalkowska_day palace_day river_day river_night rondo_rain_night heli_day settings_panel)
QUICK=(spawn_day spawn_night_prebuilt)

# Loop 3a: the road spots (docs/DEMO.md 4.5), one per line of tools/road_spots.txt.
ROADS=()
while read -r rname rflags; do
	[[ -z $rname || $rname == \#* ]] && continue
	SHOT[$rname]="$rflags --no-traffic --fixed --size=70"
	ROADS+=($rname)
done < $ROOT/tools/road_spots.txt
GAME=$ROOT/game

set_names=($CORE)
size=2532x1170
out=""
tag=""
extra=()
while (( $# )); do
	case $1 in
		--set=core) set_names=($CORE) ;;
		--set=quick) set_names=($QUICK) ;;
		--set=first) set_names=($FIRST) ;;
		--set=roads) set_names=($ROADS); FRAME=90 ;;
		--game=*) GAME=${1#--game=}; [[ $GAME == /* ]] || GAME=$ROOT/$GAME ;;
		--set=*) set_names=(${(s:,:)${1#--set=}}) ;;
		--size=*) size=${1#--size=} ;;
		--out=*) out=${1#--out=} ;;
		--tag=*) tag=_${1#--tag=} ;;
		--list) names=(${(k)SHOT}); print -r -- shots: ${(o)names}; print -r -- "core: $CORE"; exit 0 ;;
		-h|--help) sed -n '2,16p' $0; exit 0 ;;
		--) shift; extra=("$@"); break ;;
		*) print -r -- "unknown option $1 (try --help)"; exit 2 ;;
	esac
	shift
done
for n in $set_names; do
	(( ${+SHOT[$n]} )) || { print -r -- "unknown shot '$n' (try --list)"; exit 2; }
done
[[ $size == <->x<-> ]] || { print -r -- "--size must look like 2532x1170"; exit 2; }
[[ -z $out ]] && out=$ROOT/shots/review_$(strftime %Y%m%d-%H%M%S $EPOCHSECONDS)
[[ $out == /* ]] || out=$PWD/$out  # Godot runs in the game folder: the path must be absolute
mkdir -p $out || exit 1
(( $(pgrep -x Godot | wc -l) > 0 )) && print -r -- "note: another Godot is running; a bench beside this is disturbed"

for n in $set_names; do
	tmp=$out/.tmp_$n
	mkdir -p $tmp
	# 900 s is a safety stop only (macOS has no `timeout`): a shot takes ~10-30 s.
	( cd $GAME && perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' 900 \
		$GODOT --path . --resolution $size --fixed-fps 60 --quit-after $(( FRAME + 600 )) \
		-- --nosave --free --shots=$FRAME --out=$tmp ${=SHOT[$n]} $extra ) > $tmp/log.txt 2>&1
	png=$(printf '%s/shot_%04d.png' $tmp $FRAME)
	if [[ -f $png ]]; then
		mv $png $out/${n}${tag}_${size}.png
		print -r -- "$out/${n}${tag}_${size}.png"
		rm -rf $tmp
	else
		print -r -- "MISSING $n: $(grep -m1 -E '^(ERROR|SCRIPT ERROR)' $tmp/log.txt || tail -1 $tmp/log.txt) (log $tmp/log.txt)"
	fi
done
