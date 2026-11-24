#!/bin/zsh
# From a git ref to the beta testers in one command, behind a gate (F, 2026-11-24: the fast path;
# the long overnight process is in docs/BACKLOG.md).
#   tools/release.sh --notes=DIR               the gate, one build, internal TestFlight and Play
#                                              internal testing; remembered as the candidate
#   tools/release.sh --notes=DIR --open-beta   the same, then straight on to the outside testers:
#                                              "Beta test external" and Play open testing
#   tools/release.sh --promote --phone-ok="who, which phones"
#                                              a candidate's own files, not a rebuild, to them later
# The gate, on the exact commit: CI's `verify` green on main's push, then the `local` steps of
# tools/ci_steps.txt on this Mac (CI never runs those). The fast gate leaves the longest ones to
# the night (gate_slow below); --thorough runs all of them. A step that fails or only warns stops
# the build unless tools/release_known_red.txt names it with a reason.
# Builds in a fresh folder outside the checkout, so uncommitted work is never touched.
#
# usage: tools/release.sh [--ios] [--android] [options]     (neither flag: both)
#   --ref=REF          what to build (default origin/main, fetched first)
#   --dir=PATH         build folder (default /private/tmp/aw-release); wiped and refilled
#   --ios-build=N      force the iOS build number (default: last uploaded + 1)
#   --android-code=N   force the Android version code (default: last uploaded + 1)
#   --skip-bake        reuse the folder's prebuilt sectors (only with --keep)
#   --keep             don't wipe the build folder (a re-run after a failed upload)
#   --open-beta        go on to the outside testers once both uploads are in
#   --thorough         the gate with every local step, hours (overnight)
#   --promote          send the candidate, for the stores the candidate has (--ios / --android: only that one)
#   --phone-ok=TEXT    --promote's record of the phone check (docs/store/release.md)
#   --gate-only        build folder, bake and gate, then stop
#   --no-gate          build without the gate: internal only, never becomes a candidate
#   --notes=DIR        what's new: en-GB.txt and pl-PL.txt (up to 500 characters each); step 1 needs it
#   --no-upload        build and sign only (the AAB goes to ~/Downloads, the iOS archive stays)
#   --check-keys       only say which keys are there and whether the stores accept them
#
# Keys, none of them in git (docs/store/release.md, "Keys"), all in ~/.config/aroundwarsaw/:
#   release.env        ASC_KEY_ID=... and ASC_ISSUER_ID=...
#   AuthKey_<ID>.p8    the App Store Connect API key
#   play.json          the Google Play service account key
# Without the ASC key the iOS upload uses Xcode's own sign-in and stops at internal TestFlight;
# without play.json the AAB is left in ~/Downloads for a manual upload.
# Also copied from this checkout: game/data/stats_key.json (the PostHog token), game/icons,
# game/android (the Gradle template), game/map/lod2.* and terrain.json.
#
# The last numbers live in ~/.config/aroundwarsaw/release-numbers (ios=N, android=N); a store
# lookup wins when it is higher. Play production and the App Store are never touched.
set -e
setopt pipefail
self=${0:A}
# Local steps the fast gate skips: soaks and walks of ten minutes and more.
gate_slow=(streaming sectororder first10-run trzy-mosty police-soak life-soak lanedrive-grounded)
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8  # fastlane refuses other locales
root=${AW_ROOT:-${0:A:h:h}}  # AW_ROOT: the checkout to copy from
do_ios=0 do_android=0 ref=origin/main dir=/private/tmp/aw-release
ios_build= android_code= skip_bake=0 keep=0 promote=0 open_beta=0 thorough=0 phone_ok= gate=1 gate_only=0 upload=1 check_keys=0 notes=
for arg in "$@"; do
	case $arg in
		--ios) do_ios=1 ;;
		--android) do_android=1 ;;
		--ref=*) ref=${arg#*=} ;;
		--dir=*) dir=${arg#*=} ;;
		--ios-build=*) ios_build=${arg#*=} ;;
		--android-code=*) android_code=${arg#*=} ;;
		--skip-bake) skip_bake=1 ;;
		--keep) keep=1 ;;
		--promote) promote=1 ;;
		--open-beta) open_beta=1 ;;
		--thorough) thorough=1 ;;
		--phone-ok=*) phone_ok=${arg#*=} ;;
		--gate-only) gate_only=1 ;;
		--no-gate) gate=0 ;;
		--notes=*) notes=${${arg#*=}:a} ;;
		--check-keys) check_keys=1 ;;
		--no-upload) upload=0 ;;
		-h|--help) sed -n '2,/^set -e/p' $0 | sed '$d'; exit 0 ;;
		*) echo "unknown option: $arg" >&2; exit 2 ;;
	esac
done
(( do_ios || do_android )) || { do_ios=1; do_android=1 }
if (( open_beta && ( ! gate || ! upload || gate_only ) )); then echo "--open-beta needs the gate and the upload" >&2; exit 2; fi
(( gate_only && ! gate )) && { echo "--gate-only and --no-gate contradict" >&2; exit 2 }
(( skip_bake && ! keep )) && { echo "--skip-bake needs --keep" >&2; exit 2 }

team=S6PVT5UP7G
package=com.olshanskysoft.nocnawarszawa
state=$HOME/.config/aroundwarsaw/release-numbers
mkdir -p ${state:h}
[[ -f $state ]] || print -l "ios=0" "android=0" > $state
last() { sed -n "s/^$1=\([0-9]*\)/\1/p" $state }
record() { perl -pi -e "s/^$1=\\d+/$1=$2/" $state }
step() { print -P "\n%B== $*%b" }

# --- keys ----------------------------------------------------------------------------------
conf=$HOME/.config/aroundwarsaw
ios_app=com.olshanskysoft.aroundwarsaw
external_group="Beta test external"
env_value() { [[ -f $conf/release.env ]] && sed -n "s/^$1=[\"']\{0,1\}\([A-Za-z0-9-]*\).*/\1/p" $conf/release.env | tail -1 }
ASC_KEY_ID=${ASC_KEY_ID:-$(env_value ASC_KEY_ID || true)}
ASC_ISSUER_ID=${ASC_ISSUER_ID:-$(env_value ASC_ISSUER_ID || true)}
ASC_KEY_PATH=${ASC_KEY_PATH:-$conf/AuthKey_$ASC_KEY_ID.p8}
PLAY_JSON_KEY=${PLAY_JSON_KEY:-$conf/play.json}
have_fastlane=0; command -v fastlane > /dev/null && have_fastlane=1
export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1
for f in $ASC_KEY_PATH $PLAY_JSON_KEY; do
	if [[ -f $f && $(stat -f %Lp $f) != 600 ]]; then echo "$f must be private: chmod 600 $f" >&2; exit 1; fi
done
asc_args=() asc_json=
if [[ -n $ASC_KEY_ID && -n $ASC_ISSUER_ID && -f $ASC_KEY_PATH ]]; then
	asc_args=(-authenticationKeyPath $ASC_KEY_PATH -authenticationKeyID $ASC_KEY_ID
		-authenticationKeyIssuerID $ASC_ISSUER_ID)
	# fastlane reads the key from a JSON file: a private temporary one, removed on exit.
	asc_json=$(mktemp -t aw-asc)
	trap 'rm -f $asc_json' EXIT
	trap 'exit 130' INT TERM
	python3 -I -c 'import json,sys
print(json.dumps({"key_id":sys.argv[1],"issuer_id":sys.argv[2],"key":open(sys.argv[3]).read()}))' \
		$ASC_KEY_ID $ASC_ISSUER_ID $ASC_KEY_PATH > $asc_json
fi
asc_ready=0; [[ -n $asc_json ]] && (( have_fastlane )) && asc_ready=1
play_ready=0; [[ -f $PLAY_JSON_KEY ]] && (( have_fastlane )) && play_ready=1

# The stores' own latest numbers; empty when there is no key or the lookup fails.
store_ios() {
	(( asc_ready )) || return 0
	fastlane run latest_testflight_build_number app_identifier:$ios_app api_key_path:$asc_json \
		2>/dev/null | sed -n 's/.*Result: \([0-9][0-9]*\).*/\1/p' | tail -1 || true
}
store_android() {
	(( play_ready )) || return 0
	local track
	for track in internal alpha beta production; do
		fastlane run google_play_track_version_codes package_name:$package track:$track \
			json_key:$PLAY_JSON_KEY 2>/dev/null | sed -n 's/.*Result: \[\([0-9, ]*\)\].*/\1/p' \
			| tr -d ' ' | tr ',' '\n' || true
	done | sort -n | tail -1
}
if (( check_keys )); then
	n=$(store_ios); print "App Store Connect key: $( (( asc_ready )) && echo present || echo missing ), last build: ${n:-no answer}"
	n=$(store_android); print "Google Play key: $( (( play_ready )) && echo present || echo missing ), last version code: ${n:-no answer}"
	exit 0
fi
# Step 2: the candidate goes out as it is.
candidate=$conf/candidate
cand() { sed -n "s/^$1=//p" $candidate }
if (( promote )); then
	[[ -f $candidate ]] || { echo "no candidate: run step 1 first" >&2; exit 1 }
	[[ -n $phone_ok ]] || { echo "--promote needs --phone-ok=\"who, which phones\" (docs/store/release.md)" >&2; exit 1 }
	cios=$(cand ios) cand_code=$(cand android) cnotes=$(cand notes) csha=$(cand sha)
	if (( do_ios )) && [[ -n $cios ]] && (( ! asc_ready )); then echo "no App Store Connect key" >&2; exit 1; fi
	if (( do_android )) && [[ -n $cand_code ]] && (( ! play_ready )); then echo "no Google Play key" >&2; exit 1; fi
	[[ -s $cnotes/en-GB.txt && -s $cnotes/pl-PL.txt ]] || { echo "the candidate's notes are gone: $cnotes" >&2; exit 1 }
	print "promoting $csha  ios ${cios:--}  android ${cand_code:--}  phone check: $phone_ok"
	if (( do_ios )) && [[ -n $cios ]]; then
		step "iOS build $cios to $external_group"
		# Waits for Apple's processing, writes What to Test, adds the build to the group and sends
		# it to beta review; TestFlight tells the testers once it is approved.
		info=$(python3 -I -c 'import json,sys
d=sys.argv[1]; r=lambda f: open(d+"/"+f+".txt", encoding="utf-8").read().strip()
print(json.dumps({"default":{"whats_new":r("en-GB")},"en-US":{"whats_new":r("en-GB")},"pl":{"whats_new":r("pl-PL")}}))' $cnotes)
		fastlane pilot distribute --api_key_path $asc_json --app_identifier $ios_app \
			--app_platform ios --app_version $(cand version) --build_number $cios \
			--distribute_external true --groups "$external_group" --submit_beta_review true \
			--localized_build_info "$info"
	fi
	if (( do_android )) && [[ -n $cand_code ]]; then
		step "Android $cand_code from internal to open testing"
		empty=$(mktemp -d -t aw-play)
		fastlane supply --package_name $package --json_key $PLAY_JSON_KEY --track internal \
			--track_promote_to beta --track_promote_release_status completed \
			--version_code $cand_code --metadata_path $empty --skip_upload_apk true \
			--skip_upload_aab true --skip_upload_metadata true --skip_upload_images true \
			--skip_upload_screenshots true --skip_upload_changelogs true
	fi
	print "$(date '+%F %T')  $csha  ios=${cios:--} android=${cand_code:--}  ios_sent=$do_ios android_sent=$do_android  phone: $phone_ok" >> $conf/promoted.log
	print "\npromoted: $csha"
	exit 0
fi
if (( open_beta && do_ios && ! asc_ready )) || (( open_beta && do_android && ! play_ready )); then
	echo "--open-beta: a store key or fastlane is missing (--check-keys)" >&2; exit 1
fi
if (( gate && upload && ! gate_only )) && [[ -z $notes ]]; then echo "step 1 needs --notes=DIR (or --no-gate / --no-upload)" >&2; exit 1; fi
if [[ -n $notes ]]; then
	for l in en-GB pl-PL; do
		[[ -s $notes/$l.txt ]] || { echo "missing $notes/$l.txt" >&2; exit 1 }
		(( $(wc -m < $notes/$l.txt) <= 500 )) || { echo "$notes/$l.txt is over 500 characters" >&2; exit 1 }
	done
fi

# --- numbers -------------------------------------------------------------------------------
next_number() {  # next_number <last recorded> <store's latest or empty>
	local n=$1
	if [[ -n $2 ]] && (( $2 > n )); then n=$2; fi
	print $(( n + 1 ))
}
if (( do_ios )) && [[ -z $ios_build ]]; then ios_build=$(next_number $(last ios) "$(store_ios)"); fi
if (( do_android )) && [[ -z $android_code ]]; then android_code=$(next_number $(last android) "$(store_android)"); fi

# --- build folder --------------------------------------------------------------------------
step "build folder $dir from $ref"
if [[ $ref == origin/* ]]; then git -C $root fetch -q origin ${ref#origin/}; fi
full=$(git -C $root rev-parse $ref) sha=${$(git -C $root rev-parse --short $ref)}
if (( keep )) && [[ "$(cat $dir/RELEASE_SHA 2>/dev/null)" != $sha ]]; then
	echo "--keep: $dir holds $(cat $dir/RELEASE_SHA 2>/dev/null || echo nothing), not $sha" >&2; exit 1
fi
# The gate's first half costs nothing, so it comes before the folder.
if (( gate )); then
	step "gate: CI on $sha"
	slug=${$(git -C $root remote get-url origin)%.git}; slug=${slug#*github.com[:/]}
	ci=$(gh api "repos/$slug/actions/workflows/verify.yml/runs?head_sha=$full&event=push&branch=main" \
		--jq '.workflow_runs[0] | "\(.status) \(.conclusion)"' 2>/dev/null) || ci="no answer"
	[[ $ci == "completed success" ]] || { echo "refused: CI verify on $sha is '$ci', not green" >&2; exit 1 }
	print "CI verify: green"
fi
if (( ! keep )); then
	rm -rf $dir
	mkdir -p $dir
	git -C $root archive $ref | tar -x -C $dir
	for p in game/.godot game/icons game/android game/data/stats_key.json game/map/terrain.json; do
		[[ -e $root/$p ]] || { echo "missing $root/$p (see the header)" >&2; exit 1 }
		rsync -a $root/$p ${dir}/${p:h}/
	done
	cp $root/game/map/lod2.* $dir/game/map/
	[[ -d $root/data ]] && ln -s $root/data $dir/data
fi
[[ -s $dir/game/data/stats_key.json ]] || { echo "no PostHog token in the build" >&2; exit 1 }
print "$sha" > $dir/RELEASE_SHA

cd $dir/game
if grep -q '^AutopilotPlaytest=' project.godot; then
	echo "Autopilot is on in project.godot" >&2; exit 1
fi

# --- bake once for both --------------------------------------------------------------------
if (( ! skip_bake )); then
	step "import and bake the prebuilt city"
	godot --headless --path . --import > $dir/import.log 2>&1 || true
	python3 -I ../tools/bake_sectors.py map > /dev/null
	# Not --headless: the headless renderer drops MultiMesh and texture data.
	godot --path . --resolution 320x180 --script res://tools/bake_city.gd > $dir/bake.log 2>&1
	python3 -I ../tools/check_map_data.py
fi

# --- the gate's second half ----------------------------------------------------------------
# One verify.sh run per step, so a red step is named and none hides another.
if (( gate )); then
	step "gate: the steps CI does not run"
	glog=$conf/gate/$sha
	rm -rf $glog; mkdir -p $glog
	red=()
	for s in $(awk '!/^#/ && $2 == "local" { print $1 }' ../tools/ci_steps.txt); do
		if (( ! thorough )) && (( ${gate_slow[(Ie)$s]} )); then print "  night $s"; continue; fi
		code=0
		../tools/verify.sh --only=$s --logs=$glog/$s > $glog/$s.txt 2>&1 || code=$?
		warned=$(grep -cE '^RESULT: PASS .* [1-9][0-9]* warned' $glog/$s.txt || true)
		if (( code == 0 && warned == 0 )) && grep -q '^RESULT: PASS ([1-9]' $glog/$s.txt; then
			print "  pass  $s"
		else
			why=$(sed -n "s/^${s}[[:space:]]*|[[:space:]]*//p" ../tools/release_known_red.txt 2>/dev/null || true)
			if [[ -n $why ]]; then print -r -- "  known ${s}: $why"; else print "  RED   $s ($glog/$s.txt)"; red+=$s; fi
		fi
	done
	(( ${#red} == 0 )) || { echo "refused: red on $sha: $red" >&2; exit 1 }
	print "gate passed on $sha, logs in $glog"
	(( gate_only )) && exit 0
fi

# --- numbers into the build folder ---------------------------------------------------------
# The numbers and icon lines live only in the build folder's preset (main's preset never
# carries them: game/icons is not in git).
presets=$dir/game/export_presets.cfg
set_opt() {  # set_opt <preset name> <key> <value>: replace the key in that preset, or add it
	PRESET=$1 KEY=$2 VAL=$3 perl -0pi -e '
		my ($p, $k, $v) = @ENV{qw(PRESET KEY VAL)};
		s{(name="\Q$p\E".*?\n\[preset\.\d+\.options\]\n)(.*?)(?=\n\[preset|\z)}{
			my ($h, $b) = ($1, $2);
			$b =~ s/^\Q$k\E=.*\n?//m;
			"$h$k=$v\n$b"
		}se' $presets
}
if (( do_ios )); then
	set_opt iOS application/version "\"$ios_build\""
	set_opt iOS icons/icon_1024x1024 '"res://icons/app_icon_1024.png"'
fi
if (( do_android )); then
	set_opt Android version/code $android_code
	set_opt Android launcher_icons/main_192x192 '"res://icons/android_main_192.png"'
	set_opt Android launcher_icons/adaptive_foreground_432x432 '"res://icons/android_adaptive_foreground_432.png"'
	set_opt Android launcher_icons/adaptive_background_432x432 '"res://icons/android_adaptive_background_432.png"'
fi
print "commit $sha  ios build ${ios_build:--}  android code ${android_code:--}"

# --- iOS -----------------------------------------------------------------------------------
if (( do_ios )); then
	step "iOS build $ios_build"
	mkdir -p ../build/ios
	# Godot exports the Xcode project only (export_project_only): its closing "export failed"
	# about the .ipa is expected, so the project itself is checked instead.
	godot --headless --path . --export-release "iOS" ../build/ios/NocnaWarszawa.ipa > $dir/ios-export.log 2>&1 || true
	if grep -q 'ERROR.*[Ii]con' $dir/ios-export.log; then echo "icon error, see $dir/ios-export.log" >&2; exit 1; fi
	[[ -d ../build/ios/NocnaWarszawa.xcodeproj ]] || { echo "no Xcode project, see $dir/ios-export.log" >&2; exit 1 }
	for plist in ../build/ios/NocnaWarszawa/*-Info.plist; do
		plutil -replace CFBundleDisplayName -string "Around Warsaw" $plist
		plutil -replace CFBundleName -string "Around Warsaw" $plist
	done
	archive=$dir/build/AroundWarsaw-$ios_build.xcarchive
	xcodebuild -project ../build/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa \
		-configuration Release -destination generic/platform=iOS -archivePath $archive \
		-allowProvisioningUpdates $asc_args CODE_SIGN_IDENTITY="Apple Development" archive \
		> $dir/ios-archive.log 2>&1 || { tail -30 $dir/ios-archive.log; exit 1 }
	got=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' $archive/Info.plist)
	[[ $got == $ios_build ]] || { echo "archive has build $got, expected $ios_build" >&2; exit 1 }
	if (( upload )); then
		cat > $dir/build/ExportOptions.plist <<-EOF
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0"><dict>
			<key>method</key><string>app-store-connect</string>
			<key>destination</key><string>upload</string>
			<key>signingStyle</key><string>automatic</string>
			<key>teamID</key><string>$team</string>
			<key>uploadSymbols</key><true/>
			<key>manageAppVersionAndBuildNumber</key><false/>
		</dict></plist>
		EOF
		xcodebuild -exportArchive -archivePath $archive -exportOptionsPlist $dir/build/ExportOptions.plist \
			-exportPath $dir/build/ios-upload -allowProvisioningUpdates $asc_args \
			> $dir/ios-upload.log 2>&1 || { tail -30 $dir/ios-upload.log; exit 1 }
		grep -qE 'Upload succeeded|EXPORT SUCCEEDED' $dir/ios-upload.log || { tail -30 $dir/ios-upload.log; exit 1 }
		record ios $ios_build
		print "iOS build $ios_build uploaded to App Store Connect (internal TestFlight after processing)"
		short=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' $archive/Info.plist)
		sent_ios=$ios_build
	fi
fi

# --- Android -------------------------------------------------------------------------------
if (( do_android )); then
	step "Android version code $android_code"
	../tools/export_android.sh --skip-city
	aab=$(ls ../build/android/nocnawarszawa-*-$android_code.aab)
	cp $aab ~/Downloads/
	print "AAB: ~/Downloads/${aab:t}"
	if (( upload )); then
		if (( play_ready )); then
			meta=$dir/build/play-metadata
			rm -rf $meta; mkdir -p $meta
			skip_notes=true
			if [[ -n $notes ]]; then
				skip_notes=false
				for l in en-GB pl-PL; do
					mkdir -p $meta/$l/changelogs
					cp $notes/$l.txt $meta/$l/changelogs/$android_code.txt
				done
			fi
			fastlane supply --package_name $package --aab $aab --track internal \
				--release_status completed --json_key $PLAY_JSON_KEY --metadata_path $meta \
				--skip_upload_metadata true --skip_upload_images true --timeout 900 \
				--skip_upload_screenshots true --skip_upload_changelogs $skip_notes
			record android $android_code
			sent_android=$android_code
			print "Play internal testing: version code $android_code"
		else
			record android $android_code
			print "No Google Play key (or no fastlane): upload ~/Downloads/${aab:t} in Play Console,"
			print "Testing > Open testing > Create new release."
		fi
	fi
fi
if (( gate && upload )); then
	# The candidate keeps its own copy of the notes: step 2 must not pick up later ones.
	rm -rf $conf/candidate-notes; cp -R $notes $conf/candidate-notes
	print -l "sha=$sha" "ios=${sent_ios:-}" "android=${sent_android:-}" "version=${short:-}" \
		"notes=$conf/candidate-notes" > $candidate
	if (( open_beta )); then
		(( do_ios && do_android )) && which=() || { (( do_ios )) && which=(--ios) || which=(--android) }
		AW_ROOT=$root zsh $self --promote $which --phone-ok="fast path: gate only, no phone check"
		print "\ndone: $sha"; exit 0
	fi
	print "\ncandidate: $sha. After the phone check: tools/release.sh --promote --phone-ok=\"...\""
fi
print "\ndone: $sha"
