#!/usr/bin/env bash
# A set of takes from one Promo Mode frame (A/B/C variants), one command (skill: promo-video).
#
#   tools/promo_batch.sh MANIFEST [--still] [--dry] [--only=a,b]
#
# MANIFEST (a text file, docs/promo/PIECE.takes; # comments):
#   COPY=--cam=... --yaw=... --pitch=... --size=... --game-clock --clock=... --date=...
#   OPTS=--at=-170,250 --secs=7             # options every take shares (tools/promo_clip.sh options)
#   takeA | --wider=0   -- --promo-at=-214,250,6 --scoot-gang=-185,282,3 --people=60
#   takeB | --wider=0   -- --promo-at=-214,250,6 --scoot-gang=-198,268,3,-1 --people=60
# Each line after OPTS: NAME | OPTIONS -- EXTRA GAME FLAGS. A re-run overwrites the take of that
# name, so a take F has seen gets a new name (takeA3), never the old one.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
man=${1:?MANIFEST}; shift
pass=(); only=""
for a in "$@"; do
	case $a in --only=*) only=${a#*=} ;; --still|--dry) pass+=("$a") ;; *) echo "promo_batch: unknown $a" >&2; exit 2 ;; esac
done
copy="" opts=()
while IFS= read -r line || [[ -n $line ]]; do
	line=${line%%#*}; [[ -z ${line//[[:space:]]/} ]] && continue
	case $line in
		COPY=*) copy=${line#COPY=} ;;
		OPTS=*) read -r -a opts <<<"${line#OPTS=}" ;;
		*"|"*)
			name=$(echo "${line%%|*}" | xargs); rest=${line#*|}
			[[ -n $only && ,$only, != *,$name,* ]] && continue
			[[ -n $copy ]] || { echo "promo_batch: COPY= must come first" >&2; exit 2; }
			own=${rest%%--  *}; extra=""
			if [[ $rest == *" -- "* ]]; then own=${rest%% -- *}; extra=${rest#* -- }; fi
			read -r -a o <<<"$own"; read -r -a x <<<"$extra"
			if ((${#x[@]})); then "$here/promo_clip.sh" "$name" "$copy" "${opts[@]}" "${o[@]}" "${pass[@]}" -- "${x[@]}"
			else "$here/promo_clip.sh" "$name" "$copy" "${opts[@]}" "${o[@]}" "${pass[@]}"; fi ;;
		*) echo "promo_batch: cannot read line: $line" >&2; exit 2 ;;
	esac
done <"$man"
