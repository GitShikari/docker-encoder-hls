FROM jrottenberg/ffmpeg:4.4-ubuntu

# Install nginx
RUN apt-get update && apt-get install -y nginx

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Set the working directory
WORKDIR /app

# Expose port 80 for HTTP
EXPOSE 80

# Start nginx and run the entrypoint script
CMD service nginx start && /app/entrypoint.sh
