#!/bin/zsh
# Prebuild the city, then export the Godot project as an Xcode project in build/ios.
set -e
cd "${0:A:h}/../game"
# The Autopilot playtest autoload must never ship (tools/autopilot.sh).
if grep -q '^AutopilotPlaytest=' project.godot; then
	echo "Autopilot is on in project.godot: run tools/autopilot.sh off first" >&2; exit 1
fi
# A clone Godot has never opened is imported first (tools/export_android.sh: without it the
# bake can't resolve the add-ons' class names and the export crashes in its first import).
[[ -d .godot/imported ]] || godot --headless --path . --import
# Loop 3c: the map split into 512 m sectors (index.json, sectors/<i>_<j>.json), then each
# sector's scene, the proxies and the index (sectors/s_<i>_<j>.scn, proxies.scn, index.res).
# Loop 3d-1: the GUGiK outputs (lod2.*, terrain.json) are derived too: made first when missing.
if [[ ! -f map/lod2.bin || ! -f map/lod2.json || ! -f map/terrain.json ]]; then
	../tools/setup_map.sh --full
fi
python3 -I ../tools/bake_sectors.py map > /dev/null
# Not --headless: the headless renderer discards MultiMesh and texture data, which would
# leave the prebuilt city without trees, cars or AO. This opens a window for a moment.
godot --path . --resolution 320x180 --script res://tools/bake_city.gd
mkdir -p ../build/ios
godot --headless --path . --export-debug "iOS" ../build/ios/NocnaWarszawa.ipa
# Loop 2b: Xcode's Run button attaches the debugger and, by default, Metal API validation and
# GPU frame capture, which make every draw call several times slower on the phone. Switch both
# off in the scheme Godot writes (Product > Scheme > Edit Scheme > Run > Diagnostics/Options).
scheme=../build/ios/NocnaWarszawa.xcodeproj/xcshareddata/xcschemes/NocnaWarszawa.xcscheme
if [[ -f $scheme ]] && ! grep -q enableGPUValidationMode $scheme; then
	perl -0pi -e 's/(<LaunchAction\s+buildConfiguration = "Debug")/$1\n      enableGPUFrameCaptureMode = "3"\n      enableGPUValidationMode = "1"/' $scheme
fi
# The home-screen name: Godot writes the project name with its spaces stripped ("AroundWarsaw")
# into Info.plist, so set the display name ourselves after every export.
for plist in ../build/ios/NocnaWarszawa/*Info.plist(N); do
	plutil -replace CFBundleDisplayName -string "Around Warsaw" $plist
	plutil -replace CFBundleName -string "Around Warsaw" $plist
done
echo "Open build/ios/NocnaWarszawa.xcodeproj in Xcode and press Run."
echo "For frame-rate numbers, start the game from the iPhone's home screen (no debugger attached)."
