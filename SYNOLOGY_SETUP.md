# MySite op Synology NAS met Docker

## Vereisten

- Synology NAS met DSM 7.0+
- **Container Manager** geïnstalleerd (Package Center)
- SSH toegang (optioneel, voor command line)
- Minimaal 2GB RAM beschikbaar

## Installatie via Container Manager (GUI)

### Stap 1: Installeer Container Manager

1. Open **Package Center**
2. Zoek naar **Container Manager** (voorheen Docker)
3. Klik **Installeren**

### Stap 2: Maak directories aan

Via **File Station**:
```
/docker/mysite/
├── app/          (upload hier je MySite code)
├── data/         (database bestanden)
├── sessions/     (sessie bestanden)
└── logs/         (log bestanden)
```

### Stap 3: Upload code

1. Open **File Station**
2. Navigeer naar `/docker/mysite/app/`
3. Upload alle MySite bestanden
4. Zorg dat `Dockerfile` en `docker-compose.yml` aanwezig zijn

### Stap 4: Configureer environment

1. Kopieer `.env.example` naar `.env`
2. Bewerk `.env` en wijzig:
   ```bash
   SESSION_SECRET=$(openssl rand -base64 32)
   ```

### Stap 5: Build en start via Container Manager

#### Optie A: Via GUI (eenvoudigst)

1. Open **Container Manager**
2. Ga naar **Project** tab
3. Klik **Create**
4. Selecteer pad: `/docker/mysite/app`
5. Klik **Next** en **Done**
6. Container start automatisch

#### Optie B: Via command line (geavanceerd)

SSH naar je Synology:
```bash
ssh admin@synology-ip

# Navigeer naar app directory
cd /volume1/docker/mysite/app

# Build image
sudo docker build -t mysite:latest .

# Start met docker-compose
sudo docker-compose up -d

# Check logs
sudo docker-compose logs -f mysite
```

### Stap 6: Configureer reverse proxy (optioneel)

Voor toegang via mooie URL (bijv. `mysite.local`):

1. Open **Control Panel** → **Login Portal** → **Advanced**
2. Klik **Reverse Proxy**
3. Klik **Create**:
   - **Source**:
     - Protocol: `HTTP` of `HTTPS`
     - Hostname: `mysite.local` (of je gekozen naam)
     - Port: `80` of `443`
   - **Destination**:
     - Protocol: `HTTP`
     - Hostname: `localhost`
     - Port: `5000`
4. Klik **Save**

### Stap 7: Configureer firewall

**Control Panel** → **Security** → **Firewall**:
- Sta poort 5000 toe (of alleen via reverse proxy op 80/443)

## Updates

### Via Container Manager GUI

1. Stop de container
2. Upload nieuwe code via File Station
3. Rebuild image (Project → Select → Build)
4. Start container opnieuw

### Via command line

```bash
cd /volume1/docker/mysite/app
sudo git pull  # Als je git gebruikt
sudo docker-compose down
sudo docker-compose build --no-cache
sudo docker-compose up -d
```

## Monitoring

### Via Container Manager

1. Open **Container Manager**
2. Ga naar **Container** tab
3. Selecteer `mysite-app`
4. Klik **Details** voor logs en resource gebruik

### Via command line

```bash
# Logs bekijken
sudo docker logs -f mysite-app

# Resource gebruik
sudo docker stats mysite-app

# Container status
sudo docker ps -a
```

## Backup

### Data backup

Via **Hyper Backup**:
1. Voeg toe: `/docker/mysite/data`
2. Stel backup schema in

### Manual backup

```bash
# Backup database
sudo docker exec mysite-app sqlite3 /app/db/mysite .dump > mysite-backup.sql

# Of kopieer hele data directory
sudo tar -czf mysite-backup-$(date +%Y%m%d).tar.gz /volume1/docker/mysite/data
```

## Troubleshooting

### Container start niet

```bash
# Check logs
sudo docker logs mysite-app

# Check of poort 5000 vrij is
sudo netstat -tlnp | grep 5000

# Herstart container
sudo docker restart mysite-app
```

### Kan niet verbinden

1. Check of container draait: Container Manager → Container tab
2. Check firewall: Control Panel → Security → Firewall
3. Test lokaal: `curl http://localhost:5000`

### Database problemen

```bash
# Backup maken
sudo docker exec mysite-app cp /app/db/mysite /app/db/mysite.backup

# Database resetten (LET OP: verliest data!)
sudo docker exec mysite-app rm /app/db/mysite
sudo docker restart mysite-app
```

### Permissions problemen

```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) /volume1/docker/mysite/
```

## Performance tips voor Synology

1. **SSD Cache**: Gebruik SSD cache voor Docker volumes (indien beschikbaar)
2. **RAM**: Reserveer minimaal 512MB voor de container
3. **CPU**: Beperk tot 2 cores max (tenzij krachtige NAS)
4. **Logs**: Roter logs om disk space te sparen:
   ```yaml
   # In docker-compose.yml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

## Upgrade naar PostgreSQL (optioneel)

Voor betere performance met meerdere gebruikers:

1. Uncomment de `postgres` service in `docker-compose.yml`
2. Update `mysite` service environment:
   ```yaml
   environment:
     DB_TYPE: Pg
     DB_HOST: postgres
     DB_PORT: 5432
     DB_NAME: mysite
     DB_USER: mysite_user
     DB_PASSWORD: ${DB_PASSWORD}
   ```
3. Rebuild en restart: `sudo docker-compose up -d --build`

## Automatische updates met Watchtower (optioneel)

Voeg toe aan `docker-compose.yml`:
```yaml
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 86400  # Check dagelijks
```

## Support

- Synology Community: https://community.synology.com
- Docker documentatie: https://docs.docker.com
- Container Manager handleiding: DSM Help → Container Manager
