#!/bin/sh

# Surf Report Update Script for Coolify Cron Container
echo "===========================================" 
echo "🏄‍♂️ SURF REPORT UPDATE - $(date)"
echo "===========================================" 

# Environment variables with defaults
BUN_SERVICE_URL="${BUN_SERVICE_URL:-https://xoc8k88s8o044kk4080k4kwc.mttwhlly.cc}"
VERCEL_URL="${VERCEL_URL:-https://surf-report-rouge.vercel.app}"
CRON_SECRET="${CRON_SECRET:-surf-forecast-refresh-2024-secure-key}"

# Validate required environment variables
if [ -z "$BUN_SERVICE_URL" ]; then
    echo "❌ ERROR: BUN_SERVICE_URL environment variable not set"
    exit 1
fi

if [ -z "$CRON_SECRET" ]; then
    echo "❌ ERROR: CRON_SECRET environment variable not set"
    exit 1
fi

echo "🎯 Calling Bun service: $BUN_SERVICE_URL/cron/generate-fresh-report"

# Create temporary file for response
TEMP_RESPONSE="/tmp/surf_response_$(date +%s).json"

# Call the working Bun service directly
HTTP_CODE=$(curl -s -w "%{http_code}" \
    --max-time 45 \
    --retry 2 \
    --retry-delay 5 \
    -H "Content-Type: application/json" \
    -H "User-Agent: SurfLab-Coolify-Cron/2.0" \
    -X POST "$BUN_SERVICE_URL/cron/generate-fresh-report" \
    -d "{
        \"cronSecret\": \"$CRON_SECRET\",
        \"vercelUrl\": \"$VERCEL_URL\"
    }" \
    -o "$TEMP_RESPONSE")

echo "📊 HTTP Response Code: $HTTP_CODE"

# Check if request was successful
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS: Surf report generated successfully!"
    
    # Show response content (formatted with jq if available)
    echo "📋 Response Details:"
    if command -v jq >/dev/null 2>&1; then
        cat "$TEMP_RESPONSE" | jq '.'
    else
        cat "$TEMP_RESPONSE"
    fi
    
    # Extract report info using jq
    if command -v jq >/dev/null 2>&1; then
        REPORT_ID=$(cat "$TEMP_RESPONSE" | jq -r '.actions.new_report_id // "unknown"')
        REPORT_LENGTH=$(cat "$TEMP_RESPONSE" | jq -r '.actions.report_quality.length // "unknown"')
        BACKEND=$(cat "$TEMP_RESPONSE" | jq -r '.backend // "unknown"')
        
        echo "🆔 Generated report: $REPORT_ID"
        echo "📏 Report length: $REPORT_LENGTH characters"
        echo "⚡ Backend: $BACKEND"
    fi
    
elif [ "$HTTP_CODE" = "401" ]; then
    echo "❌ ERROR: Unauthorized - check CRON_SECRET"
    cat "$TEMP_RESPONSE"
    
elif [ "$HTTP_CODE" = "500" ]; then
    echo "❌ ERROR: Bun service error"
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

# Exit with appropriate code for monitoring
if [ "$HTTP_CODE" = "200" ]; then
    exit 0
else
    exit 1
fi