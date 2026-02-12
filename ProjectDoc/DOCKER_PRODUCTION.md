

# MySite productie-setup op Ubuntu met Docker Compose

Deze handleiding beschrijft het installeren en draaien van je Dancer2-applicatie met SQLite database op Ubuntu 24.04 LTS, via `docker-compose.prod.yml`. Optionele uitbreidingen zoals PostgreSQL en Redis worden onderaan kort toegelicht.



## Systeemvereisten

- Ubuntu Server 24.04 LTS (met internettoegang)
- Gebruiker met sudo-rechten
- Minimaal 2GB RAM beschikbaar

## Installatie van Docker en Docker Compose plugin

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker

# Voeg je user toe aan de docker groep (log daarna opnieuw in of gebruik newgrp)
sudo usermod -aG docker $USER
newgrp docker
```

## Directory-structuur op de host

De standaard-setup gebruikt de projectmap (bijvoorbeeld `/opt/mysite` of je home directory). De SQLite database en logbestanden worden op de host opgeslagen in de mappen `db/` en `logs/`.

## Code plaatsen

Plaats alle MySite-bestanden in de gewenste directory, bijvoorbeeld `/opt/mysite/`.



## Applicatie starten

Ga naar de projectmap en start de applicatie:

```bash
docker compose -f docker-compose.prod.yml up -d
```

De app draait nu op poort 3000 van je host. Test met:

```bash
curl http://localhost:3000
```

Stoppen en verwijderen:

```bash
docker compose -f docker-compose.prod.yml down
```


## Backups

Maak een backup van de SQLite database door simpelweg het bestand te kopiëren:

```bash
cp db/mysite db/mysite.backup
```

Of maak een SQL-dump vanuit de container:

```bash
docker exec mysite-app sqlite3 /app/db/mysite .dump > mysite-backup.sql
```


## Firewall instellen (ufw, optioneel)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 3000/tcp   # Toegang tot de app
sudo ufw enable
```

## Monitoring en beheer

- Status containers: `docker ps`
- Logs: `docker logs -f mysite-app` of `docker compose logs -f mysite`
- Resources: `docker stats mysite-app`
- Restart: `docker restart mysite-app` of `docker compose restart mysite`

## Updates

```bash
docker compose -f docker-compose.prod.yml down
git pull   # of update je code op andere wijze
docker compose -f docker-compose.prod.yml up -d --build
```

## Problemen oplossen

- Container start niet: `docker compose logs mysite`
- Poort bezet: `ss -tlnp | grep 3000`
- Permissies: `sudo chown -R $USER:$USER /opt/mysite` (of je projectmap)

## Optionele uitbreidingen

Wil je later uitbreiden met PostgreSQL of Redis? Dit vereist aanpassingen aan de Dockerfile en een alternatieve docker-compose configuratie. Zie eventueel oudere versies van deze handleiding of vraag om advies.

- **PostgreSQL**: Voor betere performance en multi-user support. Je vervangt SQLite door een PostgreSQL service en past de app-config aan.
- **Redis**: Voor snelle, gedeelde sessieopslag. Je voegt een Redis service toe en configureert Dancer2 voor Redis sessions.

Deze uitbreidingen zijn niet standaard geactiveerd in de huidige setup.


## Security Tips

1. Gebruik sterke wachtwoorden voor eventuele uitbreidingen.
2. Update images regelmatig: `docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d`
3. Expose alleen noodzakelijke poorten (standaard 3000).


## Vragen?

Voor hulp of uitbreidingen: zie de projectdocumentatie of neem contact op met de beheerder.

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
