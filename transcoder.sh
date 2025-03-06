#!/bin/bash

# Configuration
SOURCE_URL="${SOURCE_URL}"
OUTPUT_DIR="/app/hls"
LOG_DIR="/app/logs"
LOG_FILE="${LOG_DIR}/transcoder.log"
SUPPRESS_LOGS="${SUPPRESS_LOGS:-true}"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${LOG_DIR}"

# Function to log messages
log() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] $1" >> "${LOG_FILE}"
  if [ "${SUPPRESS_LOGS}" != "true" ]; then
    echo "[${timestamp}] $1"
  fi
}

# Function to check if the source stream is accessible
check_stream() {
  log "Checking stream at ${SOURCE_URL}"
  if curl -s -I "${SOURCE_URL}" | grep -q "200 OK"; then
    log "Stream is accessible"
    return 0
  else
    log "Stream is not accessible"
    return 1
  fi
}

# Function to clean up old segments
cleanup_old_segments() {
  log "Cleaning up old segments"
  find "${OUTPUT_DIR}" -name "*.ts" -type f -mmin +30 -delete
}

# Function to transcode the stream
transcode_stream() {
  log "Starting transcoding process"
  
  # Set FFmpeg log level based on SUPPRESS_LOGS
  local log_level="error"
  if [ "${SUPPRESS_LOGS}" != "true" ]; then
    log_level="info"
  fi
  
  # Run FFmpeg with error handling
  ffmpeg -loglevel ${log_level} -i "${SOURCE_URL}" \
    -map 0:v -map 0:a -c:a aac -ar 48000 -b:a 128k \
    -c:v libx264 -preset veryfast -crf 22 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 5000k -maxrate 5350k -bufsize 7500k -filter:v "scale=1920:1080" \
    -f hls -hls_time 6 -hls_list_size 10 -hls_flags independent_segments \
    -master_pl_name master.m3u8 -var_stream_map "v:0,a:0" \
    -hls_segment_filename "${OUTPUT_DIR}/1080p_%03d.ts" "${OUTPUT_DIR}/1080p.m3u8" \
    -c:v libx264 -preset veryfast -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 2800k -maxrate 3000k -bufsize 4200k -filter:v "scale=1280:720" \
    -f hls -hls_time 6 -hls_list_size 10 -hls_flags independent_segments \
    -var_stream_map "v:0,a:0" \
    -hls_segment_filename "${OUTPUT_DIR}/720p_%03d.ts" "${OUTPUT_DIR}/720p.m3u8" \
    -c:v libx264 -preset veryfast -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 1400k -maxrate 1498k -bufsize 2100k -filter:v "scale=854:480" \
    -f hls -hls_time 6 -hls_list_size 10 -hls_flags independent_segments \
    -var_stream_map "v:0,a:0" \
    -hls_segment_filename "${OUTPUT_DIR}/480p_%03d.ts" "${OUTPUT_DIR}/480p.m3u8" \
    -c:v libx264 -preset veryfast -crf 23 -g 30 -keyint_min 120 \
    -sc_threshold 0 -b:v 800k -maxrate 856k -bufsize 1200k -filter:v "scale=640:360" \
    -f hls -hls_time 6 -hls_list_size 10 -hls_flags independent_segments \
    -var_stream_map "v:0,a:0" \
    -hls_segment_filename "${OUTPUT_DIR}/360p_%03d.ts" "${OUTPUT_DIR}/360p.m3u8"
    
  local result=$?
  if [ $result -ne 0 ]; then
    log "FFmpeg process failed with exit code ${result}"
    return 1
  else
    log "FFmpeg process completed successfully"
    return 0
  fi
}

# Function to create master playlist
create_master_playlist() {
  log "Creating master playlist"
  cat > "${OUTPUT_DIR}/master.m3u8" << EOF
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=5350000,RESOLUTION=1920x1080
1080p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=1280x720
720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1498000,RESOLUTION=854x480
480p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=856000,RESOLUTION=640x360
360p.m3u8
EOF
}

# Main loop
while true; do
  if check_stream; then
    # Create master playlist
    create_master_playlist
    
    # Clean up old segments
    cleanup_old_segments
    
    # Start transcoding
    transcode_stream
    
    # If we get here, the transcoder has stopped. Check if it was a clean exit.
    log "Transcoder stopped. Restarting in 5 seconds..."
    sleep 5
  else
    log "Stream is not accessible. Retrying in 10 seconds..."
    sleep 10
  fi
done
