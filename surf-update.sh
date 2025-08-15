#!/bin/sh

# Surf Report Update Script
# This script is called by the scheduler to update the surf report

echo "===========================================" 
echo "SURF REPORT UPDATE - $(date)"
echo "===========================================" 

# Environment variables (set in Coolify)
VERCEL_URL="${VERCEL_URL:-https://your-surf-app.vercel.app}"
CRON_SECRET="${CRON_SECRET:-your-secret-here}"

# Validate required environment variables
if [ -z "$VERCEL_URL" ]; then
    echo "ERROR: VERCEL_URL environment variable not set"
    exit 1
fi

if [ -z "$CRON_SECRET" ]; then
    echo "ERROR: CRON_SECRET environment variable not set"
    exit 1
fi

echo "🔥 Warming database connection..."
curl -s -H "Authorization: Bearer $CRON_SECRET" "$VERCEL_URL/api/admin/warm-cache" > /dev/null

echo "🔄 Generating fresh surf report..."

echo "Hitting endpoint: $VERCEL_URL/api/admin/request-forecast"
echo "Using auth header: Bearer [REDACTED]"

# Create temporary file for response
TEMP_RESPONSE="/tmp/surf_response_$(date +%s).json"

# Make the request with proper headers and longer timeout
HTTP_CODE=$(curl -s -w "%{http_code}" \
    --max-time 60 \
    --retry 3 \
    --retry-delay 10 \
    --retry-max-time 180 \
    -H "Authorization: Bearer $CRON_SECRET" \
    -H "User-Agent: SurfLab-Coolify-Cron/2.0" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -X GET "$VERCEL_URL/api/admin/request-forecast" \
    -o "$TEMP_RESPONSE")

echo "HTTP Response Code: $HTTP_CODE"

# Check if request was successful
if [ "$HTTP_CODE" = "200" ]; then
    echo "SUCCESS: Surf report cron job completed successfully!"
    
    # Show response content (parse if JSON)
    echo "Response Details:"
    if command -v jq >/dev/null 2>&1; then
        # If jq is available, pretty print JSON
        jq '.' "$TEMP_RESPONSE" 2>/dev/null || cat "$TEMP_RESPONSE"
    else
        # Otherwise just show raw content
        cat "$TEMP_RESPONSE"
    fi
    
    # Extract key info if possible
    if command -v jq >/dev/null 2>&1; then
        NEW_REPORT_ID=$(jq -r '.actions.new_report_id // "unknown"' "$TEMP_RESPONSE" 2>/dev/null)
        CLEARED_COUNT=$(jq -r '.actions.cleared_reports // "unknown"' "$TEMP_RESPONSE" 2>/dev/null)
        echo ""
        echo "Key Results:"
        echo "- Cleared old reports: $CLEARED_COUNT"
        echo "- New report ID: $NEW_REPORT_ID"
    fi
    
elif [ "$HTTP_CODE" = "401" ]; then
    echo "ERROR: Unauthorized - check CRON_SECRET in both Coolify and Vercel"
    echo "Expected: Bearer $CRON_SECRET"
    cat "$TEMP_RESPONSE"
    
elif [ "$HTTP_CODE" = "500" ]; then
    echo "ERROR: Server error on Vercel - check Vercel function logs"
    cat "$TEMP_RESPONSE"
    
elif [ "$HTTP_CODE" = "000" ]; then
    echo "ERROR: Connection failed - check network and Vercel URL"
    echo "Vercel URL: $VERCEL_URL"
    cat "$TEMP_RESPONSE"
    
else
    echo "ERROR: Unexpected response code $HTTP_CODE"
    cat "$TEMP_RESPONSE"
fi

# Cleanup
rm -f "$TEMP_RESPONSE"

echo "Update completed at $(date)"
echo "Next scheduled run: see cron schedule"
echo "===========================================" 
echo ""

# Exit with appropriate code
if [ "$HTTP_CODE" = "200" ]; then
    exit 0
else
    exit 1
fi