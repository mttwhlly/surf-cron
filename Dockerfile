# Alternative: Super Simple Cron Container (Most Reliable)
FROM alpine:latest

# Install curl and cronie
RUN apk add --no-cache curl cronie tzdata

# Set timezone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

# Create script directory
RUN mkdir -p /scripts

# Copy the update script
COPY surf-update.sh /scripts/surf-update.sh
RUN chmod +x /scripts/surf-update.sh

# Create crontab with simplified schedule
RUN echo "0 9,13,17,20 * * * /scripts/surf-update.sh" > /etc/crontabs/root

# Create startup script
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "🏄‍♂️ Surf Cron Starting..."' >> /start.sh && \
    echo 'echo "⏰ Current time: $(date)"' >> /start.sh && \
    echo 'echo "📅 Schedule: 9:00, 13:00, 17:00, 20:00 UTC"' >> /start.sh && \
    echo 'echo "🌍 Timezone: $TZ"' >> /start.sh && \
    echo 'crond -f' >> /start.sh && \
    chmod +x /start.sh

# Simple healthcheck
HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
  CMD pgrep crond || exit 1

CMD ["/start.sh"]