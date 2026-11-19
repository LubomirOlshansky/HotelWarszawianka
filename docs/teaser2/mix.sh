#!/bin/bash
# usage: mix.sh MUSIC.mp3 MUSIC_START OUT.m4a
set -e
M=/mnt/project-files/teaser/music/teaser2
lufs() { ffmpeg -i "$1" -af ebur128 -f null - 2>&1 | awk '/^ +I:/{v=$2} END{print v}'; }
ffmpeg -v error -y -ss 0 -t 7.5 -i $M/rain1.mp3 -ar 48000 -ac 2 r.wav
ffmpeg -v error -y -ss 1 -t 7.5 -i $M/city4.mp3 -af lowpass=f=2000,highpass=f=120 -ar 48000 -ac 2 c.wav
ffmpeg -v error -y -ss $2 -t 7.5 -i "$1" -af "dynaudnorm=f=150:g=9:m=12:p=0.7" -ar 48000 -ac 2 p.wav
gr=$(echo "-31 - ($(lufs r.wav))" | bc -l); gc=$(echo "-38 - ($(lufs c.wav))" | bc -l); gp=$(echo "-25 - ($(lufs p.wav))" | bc -l)
ffmpeg -v error -y -i r.wav -i c.wav -i p.wav -filter_complex "[0]volume=${gr}dB[r];[1]volume=${gc}dB[c];[2]volume=${gp}dB[p];[r][c][p]amix=inputs=3:normalize=0,afade=t=in:d=0.6,afade=t=out:st=6.2:d=0.8" -t 7 mix.wav
g=$(echo "-18 - ($(lufs mix.wav))" | bc -l)
ffmpeg -v error -y -i mix.wav -af "volume=${g}dB,alimiter=limit=0.84" -c:a aac -b:a 192k -ar 48000 "$3"
echo "$3 $(lufs "$3") LUFS"
ffmpeg -v error -i "$3" -af "aresample=8000,asetnsamples=4000,astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" -f null - | grep RMS | awk -F= '{printf "%.0f ", $2}'; echo
