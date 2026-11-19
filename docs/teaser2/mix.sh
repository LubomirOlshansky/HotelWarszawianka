#!/bin/bash
# Teaser 2's sound bed, 7 s, a seamless loop (F 2026-11-19: Instagram replays the reel).
# usage: docs/teaser2/mix.sh MUSIC.mp3 MUSIC_START OUT.m4a   (raw takes in the project files, teaser/music/teaser2)
# Static gains, no loudnorm on the stems: the music levelled (a slow compressor) at -25 LUFS, the rain 8 dB
# under it, the city very soft at -38; 8 s of each, and the last second cross-faded into the first, so
# the end runs straight into the start with no fade.
set -e
M=${RAW:-/mnt/project-files/teaser/music/teaser2}
lufs() { ffmpeg -i "$1" -af ebur128 -f null - 2>&1 | awk '/^ +I:/{v=$2} END{print v}'; }
t=$(mktemp -d)
ffmpeg -v error -y -ss 0 -t 8 -i $M/rain1.mp3 -ar 48000 -ac 2 $t/r.wav
ffmpeg -v error -y -ss 1 -t 8 -i $M/city4.mp3 -af lowpass=f=2000,highpass=f=120 -ar 48000 -ac 2 $t/c.wav
ffmpeg -v error -y -ss $2 -t 8 -i "$1" -af "acompressor=threshold=0.003:ratio=8:attack=300:release=1500:knee=4" -ar 48000 -ac 2 $t/p.wav
gr=$(echo "-33 - ($(lufs $t/r.wav))" | bc -l); gc=$(echo "-38 - ($(lufs $t/c.wav))" | bc -l); gp=$(echo "-25 - ($(lufs $t/p.wav))" | bc -l)
ffmpeg -v error -y -i $t/r.wav -i $t/c.wav -i $t/p.wav -filter_complex "[0]volume=${gr}dB[r];[1]volume=${gc}dB[c];[2]volume=${gp}dB[p];[r][c][p]amix=inputs=3:normalize=0,acompressor=threshold=0.003:ratio=3:attack=300:release=1500:knee=4" -t 8 $t/m.wav
ffmpeg -v error -y -ss 0 -t 1 -i $t/m.wav -af "afade=t=in:d=1:curve=qsin" $t/h1.wav
ffmpeg -v error -y -ss 7 -t 1 -i $t/m.wav -af "afade=t=out:d=1:curve=qsin" $t/h2.wav
ffmpeg -v error -y -ss 1 -t 6 -i $t/m.wav $t/body.wav
ffmpeg -v error -y -i $t/h1.wav -i $t/h2.wav -i $t/body.wav -filter_complex "[0][1]amix=inputs=2:normalize=0[h];[h][2]concat=n=2:v=0:a=1[o]" -map "[o]" $t/loop.wav
g=$(echo "-21 - ($(lufs $t/loop.wav))" | bc -l)
ffmpeg -v error -y -i $t/loop.wav -af "volume=${g}dB,alimiter=limit=0.84" -c:a aac -b:a 192k -ar 48000 "$3"
echo "$3 $(lufs "$3") LUFS"
rm -rf $t
