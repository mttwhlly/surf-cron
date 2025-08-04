FROM alpine:latest

# Install curl and timezone data only (no cron needed)
RUN apk add --no-cache curl tzdata

# Set timezone to Eastern Time
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create directories
RUN mkdir -p /var/log/surf /scripts

# Copy the update script and scheduler
COPY surf-update.sh /scripts/surf-update.sh
COPY surf-scheduler.sh /scripts/surf-scheduler.sh
RUN chmod +x /scripts/surf-update.sh /scripts/surf-scheduler.sh

# Create log file
RUN touch /var/log/surf/surf.log

# Start the scheduler
CMD ["/scripts/surf-scheduler.sh"]