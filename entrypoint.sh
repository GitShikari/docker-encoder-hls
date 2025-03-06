#!/bin/bash

# Check if SOURCE_URL is provided
if [ -z "${SOURCE_URL}" ]; then
  echo "ERROR: SOURCE_URL environment variable is required"
  exit 1
fi

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
