#!/bin/sh

echo "=========================================="
echo "Surf Cron Scheduler Started at $(date)"
echo "Timezone: $(date)"
echo "Schedule: 5:00, 9:00, 13:00, 16:00 ET daily"
echo "=========================================="

# Keep track of last run to avoid duplicates
last_run=""

while true; do
    current_time=$(date +"%H:%M")
    current_hour=$(date +%H)
    current_minute=$(date +%M)
    current_date=$(date +"%Y-%m-%d")
    
    # Check if we're at one of the target times (5:00, 9:00, 13:00, 16:00)
    # And we haven't run today at this hour yet
    run_key="${current_date}-${current_hour}"
    
    if [ "$current_minute" = "00" ] || [ "$current_minute" = "01" ]; then
        case $current_hour in
            05|09|13|16)
                if [ "$last_run" != "$run_key" ]; then
                    echo "Triggering surf update at $(date) (Hour: $current_hour)"
                    /scripts/surf-update.sh >> /var/log/surf/surf.log 2>&1
                    last_run="$run_key"
                    echo "Update completed, sleeping for 2 minutes..."
                    sleep 120
                else
                    echo "Already ran at $current_hour today, skipping..."
                fi
                ;;
            *)
                # Not a target hour, just log we're alive every hour at :00
                if [ "$current_minute" = "00" ]; then
                    echo "Scheduler alive at $(date) - next update at next target hour"
                fi
                ;;
        esac
    fi
    
    # Sleep for 30 seconds before checking again
    sleep 30
done