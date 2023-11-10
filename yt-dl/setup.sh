#!/bin/bash

# This assumes you already have python. Install it if you don't.

sudo apt install ffmpeg

python3 -m pip install --upgrade --force-reinstall "git+https://github.com/ytdl-org/youtube-dl.git"
