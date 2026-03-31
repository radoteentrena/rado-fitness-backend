# Kamal Operations Guide

Complete reference for managing your rado_fitness application on production via Kamal.

**Server:** `200.58.98.116` (SSH port 5430)
**Image:** `blarsam/rado_fitness` (DockerHub)
**Service:** rado_fitness

---

## Prerequisites

1. **Set DockerHub credentials** (one-time setup):
```bash
export DOCKER_USERNAME="blarsam"
export DOCKER_PASSWORD="your_dockerhub_token"
```

2. **Kamal installed:**
```bash
gem install kamal
```

3. **SSH key configured** for production server

---

## Quick Start Aliases

Your project has pre-configured aliases for common tasks:

```bash
# Access Rails console
kamal console

# Access bash shell on container
kamal shell

# View live logs
kamal logs

# Access database console
kamal dbc
```

---

## Deployment

### Full Deploy (Build + Push + Deploy)

Deploy new code to production:

```bash
kamal deploy
```

This:
1. Builds Docker image locally
2. Pushes to DockerHub (`blarsam/rado_fitness`)
3. Pulls on production server
4. Restarts container with new image

---

### Redeploy Current Image

If you only changed environment variables or config (no code changes):

```bash
kamal redeploy
```

This restarts the container without rebuilding the image.

---

### Build Only (Don't Deploy)

Test build without deploying:

```bash
kamal build
```

Image is built and pushed to DockerHub but NOT deployed.

---

## Environment & Secrets Management

Secrets are stored in `.kamal/secrets` (encrypted) and injected as environment variables at runtime.

### View Current Secrets

```bash
kamal secrets
```

Shows all secrets configured in `config/deploy.yml` under `env.secret`.

### Set a Secret

```bash
kamal secrets set GOOGLE_CLIENT_ID=your_value
```

### Set Multiple Secrets

```bash
kamal secrets set \
  GOOGLE_CLIENT_ID=your_id \
  GOOGLE_CLIENT_SECRET=your_secret \
  ADMIN_EMAILS=admin@example.com
```

### Remove a Secret

```bash
kamal secrets remove GOOGLE_CLIENT_ID
```

### View Secret Values

Secrets are encrypted in `.kamal/secrets`. To see the values:

```bash
cat .kamal/secrets
```

---

## Accessing Production

### Rails Console

Interactive Rails console on production:

```bash
kamal console
```

Example usage:
```bash
kamal console
irb(main):001:0> User.count
irb(main):002:0> User.find(1)
irb(main):003:0> exit
```

### Rails Runner

Execute code without interactive console:

```bash
kamal app exec 'rails runner "puts User.count"'
```

### Bash Shell

SSH into running container:

```bash
kamal shell
```

Inside shell:
```bash
# View logs
tail -f log/production.log

# Run rails commands
rails db:migrate
rails assets:precompile

# Exit shell
exit
```

### Database Console

Connect to PostgreSQL console:

```bash
kamal dbc
```

Example queries:
```sql
\dt                          -- List tables
SELECT COUNT(*) FROM users;  -- Count users
\q                           -- Exit
```

---

## Monitoring & Logs

### View Live Logs

Stream production logs in real-time:

```bash
kamal logs
```

Follow specific pattern:
```bash
kamal logs | grep ERROR
kamal logs | grep "User authentication"
```

### View Logs from Specific Time

```bash
kamal logs --lines 100  # Last 100 lines
```

### Logs on Server

SSH into server and check Docker logs:

```bash
kamal app exec 'tail -f log/production.log'
```

---

## Server Management

### Server Status

Check if services are running:

```bash
kamal status
```

Shows:
- Service status
- Image version
- Container uptime
- Volume mounts

### Server Information

```bash
kamal server info
```

Displays:
- OS version
- Docker version
- Available disk space
- CPU/memory info

### SSH into Server

```bash
kamal server exec 'whoami'
kamal server exec 'df -h'           # Disk space
kamal server exec 'docker ps'       # Running containers
```

---

## Database Operations

### Run Migrations

```bash
kamal app exec 'rails db:migrate'
```

### Check Migration Status

```bash
kamal app exec 'rails db:migrate:status'
```

### Rollback Last Migration

```bash
kamal app exec 'rails db:rollback'
```

### Seed Database

```bash
kamal app exec 'rails db:seed'
```

### Database Console

```bash
kamal dbc
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
kamal logs

# Check image is pulled
kamal server exec 'docker images | grep rado_fitness'

# Check running containers
kamal server exec 'docker ps'
```

### Rails Command Not Found

Rebuild and redeploy (gems might be missing):

```bash
kamal build
kamal deploy
```

### Can't Connect to Database

```bash
# Check database container status
kamal server exec 'docker ps | grep db'

# Check database logs
kamal server exec 'docker logs rado_fitness-db'

# Verify database is accessible
kamal app exec 'rails dbconsole'
```

### Out of Disk Space

```bash
# Check disk usage
kamal server exec 'df -h'

# Clean up old images
kamal server exec 'docker image prune -a'

# Check specific container sizes
kamal server exec 'docker ps -a --format "table {{.Names}}\t{{.Size}}"'
```

### Want to Restart Everything

```bash
kamal reboot
```

This:
1. Stops all containers
2. Removes all containers
3. Starts everything fresh

---

## Common Workflows

### Deploy a Bug Fix

```bash
# Make changes, commit
git add .
git commit -m "fix: critical bug in auth"

# Deploy
kamal deploy

# Check logs
kamal logs | grep ERROR
```

### Add a New Environment Variable

```bash
# Add to config/deploy.yml under env.secret or env.clear
# Then:

kamal secrets set MY_NEW_VAR=value
kamal redeploy
```

### Run a One-Off Task

```bash
# Cleanup old records
kamal app exec 'rails runner "User.where(status: \"archived\").destroy_all"'

# Import data
kamal app exec 'rails runner "YourImportJob.perform_later"'

# Generate reports
kamal app exec 'rails runner "Report.generate_monthly"'
```

### Debug a Production Issue

```bash
# Check recent errors
kamal logs | tail -50

# Jump into console
kamal console

# Inspect user/data
> User.find(123).inspect
> DailyMetric.where(user_id: 123).last(5)

# Check background jobs
> SolidQueue::Job.where(status: 'failed').count
```

### Update Secrets Without Redeploying

```bash
kamal secrets set GOOGLE_CLIENT_ID=new_value
kamal redeploy
```

### Pull Latest Code and Deploy

```bash
git pull origin master
kamal deploy
```

---

## Advanced Commands

### Execute Raw Docker Command

```bash
kamal server exec 'docker exec rado_fitness-web ps aux'
```

### Get Inside Running Container

```bash
kamal app exec --interactive --reuse 'bash'
```

### Scale Web Processes

Edit `config/deploy.yml`:
```yaml
env:
  clear:
    WEB_CONCURRENCY: 4
```

Then redeploy:
```bash
kamal redeploy
```

### View Environment Variables in Container

```bash
kamal app exec 'env | sort'
```

### Check Certificate Status (Let's Encrypt)

```bash
kamal server exec 'docker exec traefik acme.json | grep -i expir'
```

---

## Kamal Config Reference

View your current config:

```bash
cat config/deploy.yml
```

Key sections:
- **service**: App name
- **image**: DockerHub image
- **servers**: Where to deploy
- **registry**: DockerHub credentials
- **env**: Environment variables and secrets
- **aliases**: Custom commands
- **accessories**: Database, Redis, etc.
- **volumes**: Persistent storage

---

## Useful One-Liners

```bash
# Count users
kamal console <<< "User.count; exit"

# Check specific user
kamal console <<< "User.find_by(email: 'user@example.com'); exit"

# View failed jobs
kamal console <<< "SolidQueue::Job.where(status: 'failed').count; exit"

# Test database connection
kamal app exec 'rails dbconsole <<< "SELECT 1;"'

# Monitor memory usage
kamal server exec 'watch -n 1 "docker stats --no-stream"'

# View last 1000 lines of logs
kamal logs --lines 1000

# Search logs for errors
kamal logs | grep -i error | tail -20
```

---

## Safety Notes

⚠️ **Always backup before major operations:**

```bash
kamal app exec 'pg_dump rado_fitness_production > backup.sql'
```

⚠️ **Test changes locally first** before deploying to production

⚠️ **Keep secrets secure** — never commit `.kamal/secrets` to git

⚠️ **Use tokens instead of passwords** for DockerHub/database credentials
