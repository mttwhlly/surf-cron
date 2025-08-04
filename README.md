# 🌊 Surf Cron Service

A lightweight Docker container that automatically updates surf reports for your surf forecasting application. This service runs scheduled tasks to keep your surf data fresh without consuming your main hosting platform's cron job quotas.

## 🎯 Purpose

This cron service is designed to work with surf forecasting applications (like [Surf Lab](https://github.com/yourusername/surf-lab)) that need regular data refreshes throughout the day. Instead of relying on limited cron jobs from platforms like Vercel's Hobby plan (2 jobs/day), this service can run on any Docker-compatible hosting platform and make unlimited scheduled updates.

## ⭐ Features

- **4x Daily Updates**: Automatically refreshes surf reports at optimal surf check times
- **Lightweight**: Minimal resource usage (~16-32MB RAM)
- **Secure**: Uses bearer token authentication to prevent unauthorized access  
- **Timezone Aware**: Runs on Eastern Time for accurate surf forecast timing
- **Robust Logging**: Detailed logs for monitoring and debugging
- **Health Checks**: Built-in health monitoring for reliable operation
- **Easy Deployment**: Works with Docker, Docker Compose, and platforms like Coolify

## 📅 Update Schedule

The service updates surf reports at these optimal times (Eastern Time):

- **5:00 AM ET** - Early morning surf check
- **9:00 AM ET** - Morning surf check  
- **1:00 PM ET** - Midday surf check
- **4:00 PM ET** - Afternoon surf check

## 🚀 Quick Start

### Prerequisites

- Docker or Docker-compatible hosting platform
- A surf forecasting app with a cron endpoint (like `/api/admin/request-forecast`)
- A secure `CRON_SECRET` shared between this service and your app

### 1. Clone and Configure

```bash
git clone https://github.com/yourusername/surf-cron.git
cd surf-cron

# Copy and edit environment variables
cp .env.example .env
nano .env
```

### 2. Set Environment Variables

```bash
# Your surf app URL
VERCEL_URL=https://your-surf-app.vercel.app

# Shared secret for authentication (generate a random 64-character string)
CRON_SECRET=your-secure-random-string-here

# Timezone (optional, defaults to America/New_York)
TZ=America/New_York
```

### 3. Deploy

**Docker Compose (Recommended):**
```bash
docker-compose up -d
```

**Plain Docker:**
```bash
docker build -t surf-cron .
docker run -d --name surf-cron \
  -e VERCEL_URL=https://your-app.vercel.app \
  -e CRON_SECRET=your-secret \
  surf-cron
```

**Coolify/Portainer/Similar:**
- Import this repository
- Set environment variables in your platform's interface
- Deploy as a Docker service

## 🔧 Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `VERCEL_URL` | ✅ | Your surf app's base URL | `https://surf-lab.vercel.app` |
| `CRON_SECRET` | ✅ | Shared authentication secret | `f8a7b2c9d4e6f1a8b3c7...` |
| `TZ` | ❌ | Container timezone | `America/New_York` |

### Generating a Secure Secret

```bash
# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Using OpenSSL  
openssl rand -hex 32

# Using system random
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64
```

**Important**: Use the same `CRON_SECRET` in both this service and your main surf app.

### Custom Schedule

To modify the update times, edit the `crontab` file:

```bash
# Example: Update every 2 hours instead
0 */2 * * * /scripts/surf-update.sh >> /var/log/cron/surf.log 2>&1
```

## 📊 Monitoring

### View Logs

```bash
# Docker Compose
docker-compose logs -f surf-cron

# Plain Docker
docker logs -f surf-cron

# Inside container
docker exec -it surf-cron tail -f /var/log/cron/surf.log
```

### Test Manually

```bash
# Run update script immediately
docker exec -it surf-cron /scripts/surf-update.sh

# Check cron status
docker exec -it surf-cron ps aux | grep crond
```

### Health Check

The service includes a health check that monitors the cron daemon:

```bash
# Check health status
docker inspect surf-cron | grep -A 5 "Health"
```

## 🏗️ Architecture

```
┌─────────────────┐    HTTP Request     ┌─────────────────┐
│   Surf Cron     │ ──────────────────→ │   Surf App      │
│   (Coolify)     │    Bearer Token     │   (Vercel)      │
└─────────────────┘                     └─────────────────┘
         │                                        │
         │                                        │
    ┌────▼────┐                              ┌────▼────┐
    │ Alpine  │                              │ Next.js │
    │ + cron  │                              │ + AI    │
    │ + curl  │                              │ + DB    │
    └─────────┘                              └─────────┘
```

### How it Works

1. **Cron daemon** runs inside Alpine Linux container
2. **Schedule triggers** at predefined surf check times
3. **Update script** makes authenticated HTTP request to your surf app
4. **Surf app** generates fresh AI reports and caches them in database
5. **Users** get instant responses from pre-generated cached data

## 🔒 Security

- **Bearer Token Authentication**: Prevents unauthorized access to your cron endpoints
- **No Sensitive Data**: Container only stores non-sensitive configuration
- **Minimal Attack Surface**: Lightweight Alpine base with only essential packages
- **Network Security**: Only makes outbound HTTPS requests

## 🛠️ Troubleshooting

### Common Issues

**Cron not running:**
```bash
docker exec -it surf-cron ps aux | grep crond
# Should show: /usr/sbin/crond -f -d 8
```

**Wrong timezone:**
```bash
docker exec -it surf-cron date
# Should show Eastern Time
```

**Authentication failing:**
```bash
# Check environment variables are set
docker exec -it surf-cron env | grep -E "(VERCEL_URL|CRON_SECRET)"

# Test endpoint manually
curl -H "Authorization: Bearer YOUR_SECRET" https://your-app.vercel.app/api/admin/request-forecast
```

**Script not executable:**
```bash
docker exec -it surf-cron ls -la /scripts/
# surf-update.sh should have execute permissions
```

### Debug Mode

To see detailed cron logging:
```bash
# Rebuild with debug logging
docker build --build-arg DEBUG=true -t surf-cron .
docker run -it surf-cron
```

## 📈 Resource Usage

- **Memory**: 16-32MB RAM
- **CPU**: Minimal (only active during updates)
- **Storage**: <100MB container size
- **Network**: 4 HTTP requests per day

Perfect for resource-constrained environments!

## 🤝 Compatible Applications

This cron service works with any application that has:
- HTTP endpoint for triggering updates
- Bearer token authentication
- JSON response format

Specifically designed for surf forecasting apps like:
- [Surf Lab](https://github.com/mttwhlly/surf-lab)
- Custom surf forecast applications
- Weather monitoring systems
- Any app needing scheduled data refreshes

## 🚢 Deployment Platforms

Tested and working on:
- ✅ **Coolify** (Recommended)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/surf-cron/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/surf-cron/discussions)
- **Documentation**: This README and inline code comments

## 🌊 Related Projects

- **[Surf Lab](https://github.com/yourusername/surf-lab)** - AI-powered surf forecasting application
- **[Ocean Data APIs](https://github.com/yourusername/ocean-apis)** - Collection of marine weather data sources

---

**Made with 🌊 for surfers who want fresh data, always.**

*Keep the stoke alive with automated surf reports!*