# Productie-klare Docker Setup met PostgreSQL en Redis

## Wat is er nieuw?

De setup is nu volledig productie-ready met **3 aparte containers**:

1. **mysite-app** - Je Dancer2 applicatie
2. **mysite-db** - PostgreSQL 16 database
3. **mysite-redis** - Redis voor sessie opslag
4. **mysite-nginx** - Nginx reverse proxy (optioneel)

## Voordelen

### PostgreSQL vs SQLite
- ✅ Ondersteunt meerdere gelijktijdige schrijfacties
- ✅ Betere performance met veel data
- ✅ Transacties en constraints
- ✅ Backup en replicatie mogelijk
- ✅ Geen file-locking problemen

### Redis vs File Sessions
- ✅ Veel sneller (in-memory)
- ✅ Automatische expiry van oude sessies
- ✅ Shared sessions over meerdere app instances
- ✅ Persistence met AOF (append-only file)
- ✅ Geen disk I/O voor elke request

### Nginx Reverse Proxy
- ✅ SSL/TLS termination
- ✅ Static file caching
- ✅ Rate limiting
- ✅ Load balancing (als je later meerdere app containers wilt)
- ✅ Compressie en security headers

## Quick Start

### 1. Genereer wachtwoorden

```bash
# Session secret
openssl rand -base64 32

# Database password
openssl rand -base64 24

# Redis password
openssl rand -base64 24
```

### 2. Configureer environment

```bash
# Kopieer example
cp .env.example .env

# Bewerk en vul wachtwoorden in
nano .env
```

### 3. Start alle services

```bash
# Build en start alles
docker-compose up -d

# Check status
docker-compose ps

# Bekijk logs
docker-compose logs -f
```

### 4. Test de applicatie

```bash
# Direct naar app (port 5000)
curl http://localhost:5000

# Via nginx reverse proxy (port 80)
curl http://localhost
```

## Database Migratie van SQLite naar PostgreSQL

Als je al een SQLite database hebt:

```bash
# 1. Export SQLite data
sqlite3 db/mysite .dump > mysite-export.sql

# 2. Clean up voor PostgreSQL compatibiliteit
sed -i 's/AUTOINCREMENT/SERIAL/g' mysite-export.sql
sed -i '/BEGIN TRANSACTION/d' mysite-export.sql
sed -i '/COMMIT/d' mysite-export.sql

# 3. Import in PostgreSQL
docker-compose exec postgres psql -U mysite_user -d mysite -f /tmp/mysite-export.sql
```

Of gebruik een migration tool zoals `pgloader`.

## Redis Session Configuratie

Voor Dancer2 met Redis sessions, voeg toe aan `config.yml`:

```yaml
engines:
  session:
    Redis:
      redis_server: redis:6379
      redis_password: YOUR_REDIS_PASSWORD
      redis_db: 0
      redis_namespace: mysite_sessions
      cookie_name: mysite_session
      cookie_duration: 86400  # 1 dag
```

## Monitoring

### Logs bekijken

```bash
# Alle services
docker-compose logs -f

# Specifieke service
docker-compose logs -f mysite
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Resource gebruik

```bash
docker stats
```

### Database toegang

```bash
# PostgreSQL console
docker-compose exec postgres psql -U mysite_user -d mysite

# Redis console
docker-compose exec redis redis-cli -a YOUR_REDIS_PASSWORD
```

## Backups

### PostgreSQL

```bash
# Backup maken
docker-compose exec postgres pg_dump -U mysite_user mysite > backup-$(date +%Y%m%d).sql

# Restore
docker-compose exec -T postgres psql -U mysite_user mysite < backup-20260105.sql

# Of met compressed backup
docker-compose exec postgres pg_dump -U mysite_user -Fc mysite > backup.dump
```

### Redis

```bash
# Redis maakt automatisch AOF backups in /data
# Extra snapshot maken:
docker-compose exec redis redis-cli -a YOUR_REDIS_PASSWORD BGSAVE

# Backup data volume
docker run --rm -v mysite_redis-data:/data -v $(pwd):/backup alpine tar czf /backup/redis-backup.tar.gz /data
```

## Scaling

### Meerdere app instances (met load balancing)

```yaml
# In docker-compose.yml
services:
  mysite:
    # ... bestaande config
    deploy:
      replicas: 3  # 3 app containers
```

Nginx zal automatisch load balancen over alle instances.

## Troubleshooting

### Database verbinding mislukt

```bash
# Check of postgres healthy is
docker-compose ps

# Test connectie
docker-compose exec mysite ping postgres

# Check credentials
docker-compose exec postgres psql -U mysite_user -d mysite -c "SELECT 1;"
```

### Redis verbinding mislukt

```bash
# Check Redis
docker-compose exec redis redis-cli -a YOUR_REDIS_PASSWORD PING

# Check vanuit app container
docker-compose exec mysite ping redis
```

### Port conflicts

Als poort 80 of 5000 al in gebruik is:

```bash
# Pas ports aan in docker-compose.yml
ports:
  - "8080:80"   # In plaats van 80:80
  - "5001:5000" # In plaats van 5000:5000
```

## Security Tips

1. **Verander alle wachtwoorden** in `.env`
2. **Gebruik sterke wachtwoorden** (min 24 characters)
3. **Expose alleen noodzakelijke ports** (alleen 80/443 via nginx)
4. **Update images regelmatig**: `docker-compose pull && docker-compose up -d`
5. **Beperk netwerk toegang** via Synology firewall

## Performance Tuning

### PostgreSQL

Voeg toe aan docker-compose.yml postgres service:

```yaml
command:
  - "postgres"
  - "-c"
  - "max_connections=100"
  - "-c"
  - "shared_buffers=256MB"
  - "-c"
  - "effective_cache_size=512MB"
```

### Redis

```yaml
command: >
  redis-server
  --appendonly yes
  --requirepass ${REDIS_PASSWORD}
  --maxmemory 256mb
  --maxmemory-policy allkeys-lru
```

### Nginx

Uncomment caching directives in `nginx/nginx.conf` voor static files.

## Upgrade Path

Om deze setup te upgraden vanuit de oude SQLite+file-sessions versie:

```bash
# 1. Stop oude setup
docker-compose down

# 2. Backup oude data
cp -r sessions sessions.backup
cp db/mysite db/mysite.backup

# 3. Pull nieuwe config
git pull

# 4. Start nieuwe setup
docker-compose up -d

# 5. Migreer data (zie "Database Migratie" sectie hierboven)
```
