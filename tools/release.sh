#!/bin/zsh
# One command from a git ref to the beta stores: TestFlight (iOS) and Google Play open testing
# (Android). Builds in a fresh folder outside the checkout, so the Mac's own uncommitted work
# (icons, store art) is never touched, bumps the build numbers, uploads, and records them.
#
# usage: tools/release.sh [--ios] [--android] [options]     (neither flag: both)
#   --ref=REF          what to build (default origin/main, fetched first)
#   --dir=PATH         build folder (default /private/tmp/aw-release); wiped and refilled
#   --ios-build=N      force the iOS build number (default: last uploaded + 1)
#   --android-code=N   force the Android version code (default: last uploaded + 1)
#   --skip-bake        reuse the folder's prebuilt sectors (only with --keep)
#   --keep             don't wipe the build folder (a re-run after a failed upload)
#   --rollout          Play: roll the open testing release out at once (default: a draft
#                      in Play Console for a person to check and roll out)
#   --no-upload        build and sign only (the AAB goes to ~/Downloads, the iOS archive stays)
#
# What it needs, none of it in git:
#   iOS      Xcode signed in to the team's Apple account (automatic signing, team S6PVT5UP7G).
#            Optional App Store Connect API key, for unattended runs and the build-number
#            lookup: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (the .p8 file).
#   Android  the upload key (tools/export_android.sh). For the upload: fastlane
#            (brew install fastlane) and a Play service account key, PLAY_JSON_KEY=<path.json>.
#            Without it the AAB is left in ~/Downloads for a manual upload in Play Console.
#   Both     game/data/stats_key.json (the PostHog token), game/icons, game/android (the
#            Gradle template), game/map/lod2.* and terrain.json in this checkout: copied over.
#
# The last numbers live in ~/.config/aroundwarsaw/release-numbers (ios=N, android=N), so two
# runs never reuse one; a store lookup (with the keys above) wins when it is higher.
# It never adds a build to an external TestFlight group or touches Play production.
set -e
setopt pipefail
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8  # fastlane refuses other locales
root=${AW_ROOT:-${0:A:h:h}}  # AW_ROOT: the checkout to copy from
do_ios=0 do_android=0 ref=origin/main dir=/private/tmp/aw-release
ios_build= android_code= skip_bake=0 keep=0 rollout=0 upload=1
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
		--rollout) rollout=1 ;;
		--no-upload) upload=0 ;;
		-h|--help) sed -n '2,30p' $0; exit 0 ;;
		*) echo "unknown option: $arg" >&2; exit 2 ;;
	esac
done
(( do_ios || do_android )) || { do_ios=1; do_android=1 }
(( skip_bake && ! keep )) && { echo "--skip-bake needs --keep" >&2; exit 2 }

team=S6PVT5UP7G
package=com.olshanskysoft.nocnawarszawa
state=$HOME/.config/aroundwarsaw/release-numbers
mkdir -p ${state:h}
[[ -f $state ]] || print -l "ios=0" "android=0" > $state
last() { sed -n "s/^$1=\([0-9]*\)/\1/p" $state }
record() { perl -pi -e "s/^$1=\\d+/$1=$2/" $state }
step() { print -P "\n%B== $*%b" }

asc_args=()
if [[ -n $ASC_KEY_ID && -n $ASC_ISSUER_ID && -f $ASC_KEY_PATH ]]; then
	asc_args=(-authenticationKeyPath $ASC_KEY_PATH -authenticationKeyID $ASC_KEY_ID
		-authenticationKeyIssuerID $ASC_ISSUER_ID)
fi

# --- numbers -------------------------------------------------------------------------------
if (( do_ios )) && [[ -z $ios_build ]]; then
	ios_build=$(( $(last ios) + 1 ))
	if (( ${#asc_args} )) && command -v fastlane > /dev/null; then
		store=$(fastlane run latest_testflight_build_number app_identifier:com.olshanskysoft.aroundwarsaw \
			api_key_path:<(print -r -- "{\"key_id\":\"$ASC_KEY_ID\",\"issuer_id\":\"$ASC_ISSUER_ID\",\"key_filepath\":\"$ASC_KEY_PATH\"}") \
			2>/dev/null | sed -n 's/.*Result: \([0-9]*\).*/\1/p' | tail -1)
		[[ -n $store ]] && (( store + 1 > ios_build )) && ios_build=$(( store + 1 ))
	fi
fi
if (( do_android )) && [[ -z $android_code ]]; then
	android_code=$(( $(last android) + 1 ))
	if [[ -f $PLAY_JSON_KEY ]] && command -v fastlane > /dev/null; then
		for track in internal alpha beta production; do
			store=$(fastlane run google_play_track_version_codes package_name:$package track:$track \
				json_key:$PLAY_JSON_KEY 2>/dev/null | sed -n 's/.*Result: \[\(.*\)\].*/\1/p' | tr -d ' ' | tr ',' '\n' | sort -n | tail -1)
			[[ -n $store ]] && (( store + 1 > android_code )) && android_code=$(( store + 1 ))
		done
	fi
fi

# --- build folder --------------------------------------------------------------------------
step "build folder $dir from $ref"
if [[ $ref == origin/* ]]; then git -C $root fetch -q origin ${ref#origin/}; fi
sha=$(git -C $root rev-parse --short $ref)
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
		if [[ -f $PLAY_JSON_KEY ]] && command -v fastlane > /dev/null; then
			status=draft; (( rollout )) && status=completed
			fastlane supply --package_name $package --aab $aab --track beta \
				--release_status $status --json_key $PLAY_JSON_KEY \
				--skip_upload_metadata true --skip_upload_images true \
				--skip_upload_screenshots true --skip_upload_changelogs true
			record android $android_code
			print "Play open testing: version code $android_code uploaded ($status)"
		else
			record android $android_code
			print "No PLAY_JSON_KEY (or no fastlane): upload ~/Downloads/${aab:t} in Play Console,"
			print "Testing > Open testing > Create new release."
		fi
	fi
fi
print "\ndone: $sha"
