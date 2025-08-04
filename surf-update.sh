#!/bin/sh

# Surf Report Update Script
# This script is called by cron to update the surf report

echo "===========================================" 
echo "🌊 SURF REPORT UPDATE - $(date)"
echo "===========================================" 

# Environment variables (set in Coolify)
VERCEL_URL="${VERCEL_URL:-https://your-surf-app.vercel.app}"
CRON_SECRET="${CRON_SECRET:-your-secret-here}"

# Validate required environment variables
if [ -z "$VERCEL_URL" ]; then
    echo "❌ ERROR: VERCEL_URL environment variable not set"
    exit 1
fi

if [ -z "$CRON_SECRET" ]; then
    echo "❌ ERROR: CRON_SECRET environment variable not set"
    exit 1
fi

echo "📡 Hitting endpoint: $VERCEL_URL/api/admin/request-forecast"

# Create temporary file for response
TEMP_RESPONSE="/tmp/surf_response_$(date +%s).json"

# Make the request with timeout and proper headers
HTTP_CODE=$(curl -s -w "%{http_code}" \
    --max-time 30 \
    --retry 2 \
    --retry-delay 5 \
    -H "Authorization: Bearer $CRON_SECRET" \
    -H "User-Agent: SurfLab-Coolify-Cron/1.0" \
    -X GET "$VERCEL_URL/api/admin/request-forecast" \
    -o "$TEMP_RESPONSE")

echo "📊 HTTP Response Code: $HTTP_CODE"

# Check if request was successful
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS: Surf report updated successfully!"
    
    # Show the response (pretty print if possible)
    if command -v jq >/dev/null 2>&1; then
        echo "📄 Response Details:"
        cat "$TEMP_RESPONSE" | jq .
    else
        echo "📄 Raw Response:"
        cat "$TEMP_RESPONSE"
    fi
    
    # Extract report ID if available
    if command -v grep >/dev/null 2>&1; then
        REPORT_ID=$(cat "$TEMP_RESPONSE" | grep -o '"new_report_id":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$REPORT_ID" ]; then
            echo "🆔 New Report ID: $REPORT_ID"
        fi
    fi
    
elif [ "$HTTP_CODE" = "401" ]; then
    echo "🔐 ERROR: Unauthorized - check CRON_SECRET"
    cat "$TEMP_RESPONSE"
    
elif [ "$HTTP_CODE" = "500" ]; then
    echo "💥 ERROR: Server error on Vercel"
    cat "$TEMP_RESPONSE"
    
else
    echo "❌ ERROR: Unexpected response code $HTTP_CODE"
    cat "$TEMP_RESPONSE"
fi

# Cleanup
rm -f "$TEMP_RESPONSE"

echo "⏰ Update completed at $(date)"
echo "===========================================" 
echo ""

# Exit with appropriate code
if [ "$HTTP_CODE" = "200" ]; then
    exit 0
else
    exit 1
fi