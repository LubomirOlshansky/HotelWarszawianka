#!/bin/zsh
# The site turntable: every side of ONE landmark on one PNG sheet in about a minute, so a builder
# and F can check a model from all round instead of taking ten single shots.
#
#   tools/turntable.sh KEY [--looks=lit,flat,sil] [--out=DIR] [--tile=480x360] [-- game flags]
#
# KEY is a landmark site key (game/scripts/landmarks.gd; `rotunda`, `palace`, `dom_partii`).
# game/tools/site_cams.gd builds the site alone (milliseconds) and works out the cameras from its
# bounding box: 8 yaws at pitch -25 (lo_000 ... lo_315), 8 at pitch -50 (hi_*) and `top`. Then one
# game run per look, in parallel (--solo=KEY --solo-look=lit|flat|sil, --cams, one shot each; the
# lit look takes lo + hi + top, the others lo + top), and game/tools/shot_sheet.gd pastes them:
#   row 1 lit lo, row 2 lit hi, row 3 flat lo, row 4 sil lo, row 5 the tops (lit, flat, sil);
#   columns left to right: yaw 0, 45, ... 315 (0 = the view from the south, the camera's default).
# Output in DIR (default shots/turntable_KEY/): the single PNGs (KEY_<look>_<cam>.png) and
# KEY_turntable.png; the last line printed is the sheet's path and the legend.
# Every run passes --nosave and quits by itself. With no display (Linux) it runs under xvfb-run.
# Extra game flags after `--` go to every run (e.g. `-- --prebuilt`). A look that fails prints
# MISSING with its log's last error; the sheet then has dark tiles for it.

emulate -L zsh
setopt extendedglob
zmodload zsh/datetime

ROOT=${0:A:h:h}
GAME=$ROOT/game
GODOT=${GODOT:-godot}
FRAME=30

key=""
looks=(lit flat sil)
out=""
tile=480x360
extra=()
while (( $# )); do
	case $1 in
		--looks=*) looks=(${(s:,:)${1#--looks=}}) ;;
		--out=*) out=${1#--out=} ;;
		--tile=*) tile=${1#--tile=} ;;
		-h|--help) sed -n '2,20p' $0; exit 0 ;;
		--) shift; extra=("$@"); break ;;
		-*) print -r -- "unknown option $1 (try --help)"; exit 2 ;;
		*) [[ -z $key ]] && key=$1 || { print -r -- "one KEY only"; exit 2; } ;;
	esac
	shift
done
[[ -n $key ]] || { print -r -- "usage: tools/turntable.sh KEY [--looks=lit,flat,sil] [--out=DIR] [--tile=480x360]"; exit 2; }
[[ $key =~ ^[a-z0-9_]+$ ]] || { print -r -- "KEY '$key' is not a site key"; exit 2; }
[[ $tile == <->x<-> ]] || { print -r -- "--tile must look like 480x360"; exit 2; }
for l in $looks; do
	[[ $l == (lit|flat|sil) ]] || { print -r -- "unknown look '$l' (lit, flat, sil)"; exit 2; }
done
[[ -z $out ]] && out=$ROOT/shots/turntable_$key
[[ $out == /* ]] || out=$PWD/$out  # Godot runs in the game folder: the path must be absolute
mkdir -p $out || exit 1
[[ $OSTYPE == linux* && -z $VK_ICD_FILENAMES && -f /usr/share/vulkan/icd.d/lvp_icd.json ]] && export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json

# A display for the game runs: xvfb-run when there is none (Linux), as tools/verify.sh does.
wrap=()
if [[ $OSTYPE == linux* && -z $DISPLAY && -z $WAYLAND_DISPLAY ]]; then
	if (( $+commands[xvfb-run] )); then
		wrap=(xvfb-run -a -s "-screen 0 1280x720x24")
	else
		print -r -- "no display and no xvfb-run: install xvfb, or run where there is a window"; exit 1
	fi
fi
# macOS has no `timeout`: a perl alarm is the safety stop (a run takes ~30-60 s).
guard() { local secs=$1; shift; perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' $secs "$@" }

t0=$EPOCHREALTIME
# 1. the cameras
guard 120 $GODOT --headless --path $GAME --script res://tools/site_cams.gd -- --site=$key --tile=$tile > $out/site_cams.log 2>&1
cams_all=$(sed -n 's/^cams: //p' $out/site_cams.log)
lift=$(sed -n 's/^lift: //p' $out/site_cams.log)
if [[ -z $cams_all || -z $lift ]]; then
	grep -m1 '^site_cams:' $out/site_cams.log || tail -3 $out/site_cams.log
	exit 1
fi
grep -m1 '^site_cams:' $out/site_cams.log

# 2. one game run per look, in parallel
for look in $looks; do
	cams=(${(s:+:)cams_all})
	[[ $look != lit ]] && cams=(${(M)cams:#(lo_|top)*})
	tmp=$out/.tmp_$look
	rm -rf $tmp; mkdir -p $tmp
	( cd $GAME && $wrap perl -e 'alarm shift; exec @ARGV or die "cannot run $ARGV[0]: $!\n"' 600 \
		$GODOT --path . --resolution $tile --fixed-fps 60 --quit-after $(( FRAME + 3000 )) \
		-- --nosave --nohud --no-traffic --quality=low --time=day --shots=$FRAME --out=$tmp \
		--solo=$key --solo-look=$look --lift=$lift "--cams=${(j:+:)cams}" $extra ) > $tmp/log.txt 2>&1 &
done
wait

# 3. the sheet: rows lit lo, lit hi, flat lo, sil lo, then the tops
files=()
rm -f $out/${key}_*.png(N)
yaws=(000 045 090 135 180 225 270 315)
for spec in "lit lo" "lit hi" "flat lo" "sil lo"; do
	s=(${=spec})
	(( ${looks[(I)$s[1]]} )) || continue
	for y in $yaws; do
		src=$out/.tmp_$s[1]/${s[2]}_${y}_$(printf '%04d' $FRAME).png
		dst=$out/${key}_${s[1]}_${s[2]}_${y}.png
		[[ -f $src ]] && { mv $src $dst; files+=($dst) } || files+=($dst)
	done
done
for look in $looks; do
	src=$out/.tmp_$look/top_$(printf '%04d' $FRAME).png
	dst=$out/${key}_${look}_top.png
	[[ -f $src ]] && mv $src $dst
	files+=($dst)
done
for look in $looks; do
	got=($out/${key}_${look}_*.png(N))
	if (( ! $#got )); then
		print -r -- "MISSING look $look: $(grep -m1 -E '^(ERROR|SCRIPT ERROR)' $out/.tmp_$look/log.txt || tail -1 $out/.tmp_$look/log.txt) (log $out/.tmp_$look/log.txt)"
	else
		rm -rf $out/.tmp_$look
	fi
done
sheet=$out/${key}_turntable.png
guard 120 $GODOT --headless --path $GAME --script res://tools/shot_sheet.gd -- --out=$sheet --cols=8 $files > $out/shot_sheet.log 2>&1
grep -E '^shot_sheet: (missing|none)' $out/shot_sheet.log
[[ -f $sheet ]] || { print -r -- "no sheet: $(tail -2 $out/shot_sheet.log)"; exit 1; }
printf '%s  (%.0f s)  rows: lit lo (pitch -25), lit hi (-50), flat lo, sil lo, tops lit|flat|sil; columns: yaw 0 45 90 135 180 225 270 315\n' $sheet $(( EPOCHREALTIME - t0 ))
