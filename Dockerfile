FROM alpine:3.18

# Install required packages
RUN apk add --no-cache ffmpeg bash supervisor nginx curl jq

# Create directory structure
RUN mkdir -p /app/transcoder /app/hls /app/logs /app/www

# Copy files
COPY entrypoint.sh /app/
COPY transcoder.sh /app/
COPY supervisord.conf /etc/supervisor/conf.d/
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY www/* /app/www/

# Make scripts executable
RUN chmod +x /app/entrypoint.sh /app/transcoder.sh

# Expose port for web interface
EXPOSE 8080

# Set environment variables
ENV SOURCE_URL=""
ENV CHECK_INTERVAL=10
ENV SUPPRESS_LOGS=true

# Set working directory
WORKDIR /app

# Entry point
ENTRYPOINT ["/app/entrypoint.sh"]
