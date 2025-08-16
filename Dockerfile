FROM alpine:latest

# Install curl, jq for JSON parsing, and cronie for cron
RUN apk add --no-cache curl jq cronie tzdata

# Set timezone to Eastern Time
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create directories
RUN mkdir -p /var/log/surf /scripts

# Copy the update script
COPY surf-update.sh /scripts/surf-update.sh
RUN chmod +x /scripts/surf-update.sh

# Create crontab file with surf report schedule
# Times are in UTC, adjusted for Eastern Time:
# 5AM ET = 9AM UTC, 9AM ET = 1PM UTC, 1PM ET = 5PM UTC, 4PM ET = 8PM UTC
RUN echo "# Surf report updates - 4 times daily" > /etc/crontabs/root
RUN echo "0 9 * * * /scripts/surf-update.sh >> /var/log/surf/cron.log 2>&1" >> /etc/crontabs/root
RUN echo "0 13 * * * /scripts/surf-update.sh >> /var/log/surf/cron.log 2>&1" >> /etc/crontabs/root  
RUN echo "0 17 * * * /scripts/surf-update.sh >> /var/log/surf/cron.log 2>&1" >> /etc/crontabs/root
RUN echo "0 20 * * * /scripts/surf-update.sh >> /var/log/surf/cron.log 2>&1" >> /etc/crontabs/root

# Create log file
RUN touch /var/log/surf/cron.log

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD pgrep crond || exit 1

# Start cron in foreground with debug level 8 for logging
CMD ["crond", "-f", "-d", "8"]