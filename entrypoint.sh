#!/bin/bash

# Suppress ffmpeg logs
export FFREPORT="file=/dev/null:level=error"

# URL of the HLS stream
HLS_URL="https://m3u8-prx.onrender.com/willow.m3u8"

# Infinite loop to restart the stream if it fails
while true; do
  ffmpeg -i "https://m3u8-prx.onrender.com/willow.m3u8" \
    -map 0:v -map 0:a \
    -c:a aac -ar 48000 -b:a 128k \
    -c:v libx264 -crf 22 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 5000k -maxrate 5350k -bufsize 7500k -filter:v "scale=1920:1080" -f hls -hls_time 6 -hls_playlist_type event -hls_flags independent_segments -master_pl_name master.m3u8 -var_stream_map "v:0,a:0" -hls_segment_filename "1080p_%03d.ts" 1080p.m3u8 \
    -c:v libx264 -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 2800k -maxrate 3000k -bufsize 4200k -filter:v "scale=1280:720" -f hls -hls_time 6 -hls_playlist_type event -hls_flags independent_segments -var_stream_map "v:0,a:0" -hls_segment_filename "720p_%03d.ts" 720p.m3u8 \
    -c:v libx264 -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 1400k -maxrate 1498k -bufsize 2100k -filter:v "scale=854:480" -f hls -hls_time 6 -hls_playlist_type event -hls_flags independent_segments -var_stream_map "v:0,a:0" -hls_segment_filename "480p_%03d.ts" 480p.m3u8 \
    -c:v libx264 -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 800k -maxrate 856k -bufsize 1200k -filter:v "scale=640:360" -f hls -hls_time 6 -hls_playlist_type event -hls_flags independent_segments -var_stream_map "v:0,a:0" -hls_segment_filename "360p_%03d.ts" 360p.m3u8

  # If ffmpeg exits, wait for a second before restarting
  echo "Stream stopped or failed, restarting..."
  sleep 1
done
