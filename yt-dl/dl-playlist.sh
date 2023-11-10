#!/bin/bash

format=$1
shift

for arg in "$@"
do
    echo "Running youtube-dl with argument: $arg"
    if [ "$format" == "mp4" ]
    then
        youtube-dl -o '%(uploader)s/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s' $arg
    elif [ "$format" == "mp3" ]
    then
        youtube-dl -x --audio-format mp3 -o '%(uploader)s/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s' $arg
    fi
done
