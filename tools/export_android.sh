#!/bin/zsh
# Prebuild the city, then export the signed Android App Bundle for Google Play:
# build/android/nocnawarszawa-<version name>-<version code>.aab (the "Android" preset).
#
# usage: tools/export_android.sh [--skip-city] [--apk]
#   --skip-city  don't re-split the map or rebuild the prebuilt sectors when they are already
#                there and match their inputs (loop 3d-1: they are derived, not tracked, so
#                tools/setup_map.sh --if-needed still makes them when missing or stale)
#   --apk        a debug APK instead (build/android/nocnawarszawa-debug.apk, debug keystore),
#                for `adb install` on a test phone
#
# Needs (README, "Android (Google Play)"): Godot 4.7.2's Android export templates, the Android
# SDK and a JDK set in Godot's editor settings, and the upload key at
# ~/.android-keys/nocnawarszawa-upload.jks with its password in the login keychain
# (service nocnawarszawa-android-upload, account upload). No key, user or password is ever
# written to export_presets.cfg: Godot reads them from the environment below.
set -e
skip_city=0
apk=0
for arg in "$@"; do
	case $arg in
		--skip-city) skip_city=1 ;;
		--apk) apk=1 ;;
		*) echo "unknown option: $arg"; exit 2 ;;
	esac
done
cd "${0:A:h}/../game"
# The Autopilot playtest autoload must never ship (tools/autopilot.sh).
if grep -q '^AutopilotPlaytest=' project.godot; then
	echo "Autopilot is on in project.godot: run tools/autopilot.sh off first" >&2; exit 1
fi

# The version comes from the preset, so the file name and Play's version code always agree.
opts=$(awk 'f&&/^\[preset\.[0-9]+\]/{exit} /^\[preset\.[0-9]+\]/{s=0} /^name="Android"/{s=1}
	s&&/^\[preset\.[0-9]+\.options\]/{f=1} f' export_presets.cfg)
[[ -n $opts ]] || { echo "no \"Android\" preset in game/export_presets.cfg"; exit 1; }
vname=$(print -r -- $opts | sed -n 's/^version\/name="\(.*\)"/\1/p')
vcode=$(print -r -- $opts | sed -n 's/^version\/code=\([0-9]*\)/\1/p')
package=$(print -r -- $opts | sed -n 's/^package\/unique_name="\(.*\)"/\1/p')
# Perf thread (2026-11-23): the version code and commit for the play stats (play_stats.gd
# BUILD_STAMP; PostHog's app_build said "0.1" for every build). Gitignored, made at each export.
print -r -- "{\"build\": \"${vcode:-dev}\", \"commit\": \"$(git -C .. rev-parse --short HEAD 2>/dev/null || cat ../COMMIT 2>/dev/null)\"}" > data/build_stamp.json

# A clone Godot has never opened must be imported first: bake_city.gd on an unimported project
# can't resolve the add-ons' class names (PhantomCameraHost) and the export then crashes in its
# own first import (seen 2026-10-30 in a fresh clone).
[[ -d .godot/imported ]] || godot --headless --path . --import
# Loop 3d-1: the GUGiK outputs (lod2.*, terrain.json) are derived too: made first when missing.
if [[ ! -f map/lod2.bin || ! -f map/lod2.json || ! -f map/terrain.json ]]; then
	../tools/setup_map.sh --full
fi
if (( skip_city )); then
	../tools/setup_map.sh --if-needed
else
	# The same two steps as tools/export_ios.sh: the map split into 512 m sectors, then each
	# sector's scene, the proxies and the index. Not --headless: the headless renderer discards
	# MultiMesh and texture data. This opens a window for a moment.
	python3 -I ../tools/bake_sectors.py map > /dev/null
	godot --path . --resolution 320x180 --script res://tools/bake_city.gd
fi

# Godot installs the Gradle build template (game/android/build, gitignored) on the first run.
template=()
[[ -f android/build/build.gradle ]] || template=(--install-android-build-template)
mkdir -p ../build/android

if (( apk )); then
	# A debug APK needs the Gradle build to write APK, not AAB: override the format for this run.
	out=../build/android/nocnawarszawa-debug.apk
	rm -f $out
	cp export_presets.cfg ../build/android/.export_presets.cfg.bak
	trap 'mv ../build/android/.export_presets.cfg.bak export_presets.cfg' EXIT
	perl -0pi -e 's/(name="Android".*?gradle_build\/export_format=)1/${1}0/s' export_presets.cfg
	godot --headless --path . $template --export-debug "Android" $out
else
	ks=$HOME/.android-keys/nocnawarszawa-upload.jks
	[[ -f $ks ]] || { echo "no upload key at $ks (README, \"Android (Google Play)\")"; exit 1; }
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$ks
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
	GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=$(security find-generic-password -a upload \
		-s nocnawarszawa-android-upload -w) || { echo "the upload key's password is not in the login keychain"; exit 1; }
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
	out=../build/android/nocnawarszawa-$vname-$vcode.aab
	rm -f $out
	merged=android/build/build/intermediates/merged_manifests/standardRelease/processStandardReleaseManifest/AndroidManifest.xml
	rm -f $merged
	godot --headless --path . $template --export-release "Android" $out
	unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
	# Play offers the game only to phones with Vulkan (addons/nw_android_export marks Godot's
	# two Vulkan uses-features required): refuse an AAB whose merged manifest lost that.
	required=$(perl -0ne 'my @r = /<uses-feature[^>]*?"android\.hardware\.vulkan\.(?:level|version)"[^>]*?android:required="true"/g; print scalar @r' $merged 2>/dev/null)
	# ...and at the Vulkan version Godot itself asks for (its line in src/release/, required="false").
	vk_version() { perl -0ne 'print $1 if /<uses-feature[^>]*?"android\.hardware\.vulkan\.version"[^>]*?android:version="([^"]+)"/' $1 2>/dev/null }
	godot_vk=$(vk_version android/build/src/release/AndroidManifest.xml)
	merged_vk=$(vk_version $merged)
	if [[ $required != 2 || -z $godot_vk || $godot_vk != $merged_vk ]]; then
		rm -f $out
		echo "export failed: the Vulkan uses-features in $merged are not both required at Godot's"
		echo "version (required: ${required:-0} of 2; Godot asks for ${godot_vk:-?}, the AAB has ${merged_vk:-?}):"
		echo "see game/addons/nw_android_export/plugin.gd"
		exit 1
	fi
	echo "vulkan: android.hardware.vulkan.level and .version ($merged_vk) required"
fi

[[ -f $out ]] || { echo "export failed: no $out"; exit 1; }
echo "built: build/android/${out:t}"
echo "size: $(( $(stat -f %z $out) / 1048576 )) MB ($(stat -f %z $out) bytes)"
echo "package: $package  version: $vname ($vcode)"
