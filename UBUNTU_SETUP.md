# MySite op Ubuntu 24.04 met Docker Compose

## Vereisten

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

Kies een pad voor code en data, bijv. `/opt/mysite`:
```
/opt/mysite/
├── app/          (MySite code: bevat Dockerfile en docker-compose.yml)
├── data/         (database bestanden)
├── sessions/     (sessie bestanden)
└── logs/         (log bestanden)
```

Maak de directories aan en stel permissies in:
```bash
sudo mkdir -p /opt/mysite/{app,data,sessions,logs}
sudo chown -R $USER:$USER /opt/mysite
```

## Code plaatsen

Kopieer alle MySite-bestanden naar `/opt/mysite/app/` zodat `Dockerfile` en `docker-compose.yml` daar staan.

## Environment configureren

In `/opt/mysite/app/`:
```bash
cp .env.example .env
# Pas waarden aan, o.a.:
SESSION_SECRET=$(openssl rand -base64 32)
```

## Build en start

```bash
cd /opt/mysite/app
# Build image en start containers
docker compose up -d --build

# Logs checken
docker compose logs -f mysite
```

## Reverse proxy (optioneel)

Gebruik Nginx (of Traefik/Caddy) om te termineren op 80/443 en door te sturen naar `localhost:5000`.

Voorbeeld Nginx server block (HTTP):
```nginx
server {
    listen 80;
    server_name mysite.local;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
Activeer met `sudo nginx -t && sudo systemctl reload nginx`.

## Firewall (ufw)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp   # indien TLS
# Of tijdelijk rechtstreeks op 5000
# sudo ufw allow 5000/tcp
sudo ufw enable
```

## Monitoring en beheer

- Status containers: `docker ps`
- Logs: `docker logs -f mysite-app` of `docker compose logs -f mysite`
- Resources: `docker stats mysite-app`
- Restart: `docker restart mysite-app` of `docker compose restart mysite`

## Updates

```bash
cd /opt/mysite/app
# Eventueel code updaten (git pull of nieuwe upload)
docker compose down
docker compose up -d --build
```

## Backup

```bash
# SQLite dump
docker exec mysite-app sqlite3 /app/db/mysite .dump > mysite-backup.sql

# Of hele data directory archiveren
sudo tar -czf /opt/mysite/data-backup-$(date +%Y%m%d).tar.gz /opt/mysite/data
```

## Problemen oplossen

- Container start niet: `docker compose logs mysite`
- Poort bezet: `ss -tlnp | grep 5000`
- Permissies: `sudo chown -R $USER:$USER /opt/mysite`

## Upgrade naar PostgreSQL (optioneel)

1. Uncomment de `postgres` service in `docker-compose.yml`.
2. Update `mysite` environment:
   ```yaml
   environment:
     DB_TYPE: Pg
     DB_HOST: postgres
     DB_PORT: 5432
     DB_NAME: mysite
     DB_USER: mysite_user
     DB_PASSWORD: ${DB_PASSWORD}
   ```
3. Start opnieuw: `docker compose up -d --build`

## Automatische updates met Watchtower (optioneel)

Voeg toe aan `docker-compose.yml`:
```yaml
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 86400
```
