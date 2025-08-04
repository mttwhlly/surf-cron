FROM alpine:latest

# Install curl, dcron, and timezone data
RUN apk add --no-cache curl dcron tzdata

# Set timezone to Eastern Time
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create directories and set permissions
RUN mkdir -p /var/log/cron /scripts /var/spool/cron/crontabs

# Create a non-root user for cron (helps with container security)
RUN adduser -D -s /bin/sh cronuser

# Copy scripts and make executable
COPY surf-update.sh /scripts/surf-update.sh
RUN chmod +x /scripts/surf-update.sh

# Copy crontab and install it for the cronuser
COPY crontab /var/spool/cron/crontabs/cronuser
RUN chmod 0600 /var/spool/cron/crontabs/cronuser
RUN chown cronuser:cronuser /var/spool/cron/crontabs/cronuser

# Set ownership of log directory
RUN chown -R cronuser:cronuser /var/log/cron

# Create log file
RUN touch /var/log/cron/surf.log
RUN chown cronuser:cronuser /var/log/cron/surf.log

# Create a startup script to handle container initialization
RUN cat > /start-cron.sh << 'EOF'
#!/bin/sh
echo "🚀 Starting Surf Cron Service..."
echo "📅 Timezone: $(date)"
echo "👤 Running as: $(whoami)"
echo "🔧 Cron jobs loaded:"
crontab -l 2>/dev/null || echo "No crontab found"
echo ""

# Ensure log directory exists and has correct permissions
mkdir -p /var/log/cron
touch /var/log/cron/surf.log

# Start crond without trying to change process groups
# -f = foreground, -L = log level (1-8), -l = log level 8 = debug
exec crond -f -L /var/log/cron/crond.log -l 8
EOF

RUN chmod +x /start-cron.sh

# Switch to non-root user
USER cronuser

# Use the startup script instead of direct crond
CMD ["/start-cron.sh"]