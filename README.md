# 🏄‍♂️ Surf Report Cron Service

Automated cron container that generates fresh surf reports 4 times daily.

## Schedule
- 5:00 AM ET (9:00 UTC)
- 9:00 AM ET (13:00 UTC) 
- 1:00 PM ET (17:00 UTC)
- 4:00 PM ET (20:00 UTC)

## Environment Variables
- `BUN_SERVICE_URL` - URL of your Bun AI service
- `VERCEL_URL` - URL of your Vercel app  
- `CRON_SECRET` - Shared secret for authentication

## Deployment
Deploy on Coolify using this repository URL.