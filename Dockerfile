FROM alpine:latest

# Install curl, dcron, and timezone data
RUN apk add --no-cache curl dcron tzdata

# Set timezone to Eastern Time
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create directories
RUN mkdir -p /var/log/cron
RUN mkdir -p /scripts

# Copy scripts and make executable
COPY surf-update.sh /scripts/surf-update.sh
RUN chmod +x /scripts/surf-update.sh

# Copy crontab and install it
COPY crontab /etc/cron.d/surf-cron
RUN chmod 0644 /etc/cron.d/surf-cron

# Apply cron job
RUN crontab /etc/cron.d/surf-cron

# Create log file
RUN touch /var/log/cron/surf.log

# Start crond in foreground
CMD ["crond", "-f", "-d", "8"]