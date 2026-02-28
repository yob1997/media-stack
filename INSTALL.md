# Installation and Service Linking

This guide builds the stack from `docker-compose.yml` and then links services in the correct order.

## 1. Prerequisites
- Docker Engine
- Docker Compose plugin (`docker compose`)
- A Linux host with a `/data` mount (or enough local disk to create `/data`)

## 2. Create Host Folders
From the repo root:

```bash
mkdir -p \
  /data/config/{plex,sabnzbd,qbittorrent,sonarr,radarr,prowlarr,overseerr,huntarr,wg-easy,wireguard} \
  /data/downloads/complete/{movies,tv} \
  /data/downloads/incomplete \
  /data/media/{movies,tv}
```

Optional check:

```bash
tree -d -L 4 /data
```

## 3. Create `.env`
Copy and edit:

```bash
cp /home/yob/media-stack/.env.example /home/yob/media-stack/.env
```

Required values:
- `PLEX_ADVERTISE_IP`
- `SABNZBD_HOST_WHITELIST`

## 4. Add VPN Provider Config
Place your WireGuard provider config at:

`/data/config/wireguard/`

## 5. Overseerr Override
The PlexTV override is versioned in this repo and auto-mounted by Compose (this was needed for Overseerr to be able to see the Plex watchlist for auto syncing and requesting):

`/home/yob/media-stack/overrides/overseerr/plextv.js`

## 6. Start The Stack

```bash
cd /home/yob/media-stack
docker compose up -d
```

Optional docker management UI:

```bash
docker compose --profile admin up -d portainer
```

## 7. Open Service UIs
- Plex: `http://<server-lan-ip>:32400/web`
- SABnzbd (via wireguard netns): `http://<server-lan-ip>:8080`
- qBittorrent (via wireguard netns): `http://<server-lan-ip>:8081`
- Sonarr: `http://<server-lan-ip>:8989`
- Radarr: `http://<server-lan-ip>:7878`
- Prowlarr: `http://<server-lan-ip>:9696`
- Overseerr: `http://<server-lan-ip>:5055`
- Huntarr: `http://<server-lan-ip>:9705`
- wg-easy: `http://<server-lan-ip>:51821`
- Portainer (if started): `http://<server-lan-ip>:9000`

## 8. Link Services Together
Use this order so each app can discover the next one cleanly.

1. Configure download clients first.
In SABnzbd and qBittorrent, finish first-run setup and set credentials.

2. Configure Sonarr and Radarr.
Set root folders:
- Sonarr: `/data/media/tv`
- Radarr: `/data/media/movies`

Add download clients in both:
- SABnzbd URL: `http://wireguard:8080`
- qBittorrent URL: `http://wireguard:8081`

Category suggestion:
- Sonarr: `tv`
- Radarr: `movies`

3. Configure Prowlarr.
Add indexers (I use NZBgeek, NZBplanet for UseNet and TorrentLeech for qbittorrent), then go to `Settings -> Apps` and connect:
- Sonarr URL: `http://sonarr:8989`
- Radarr URL: `http://radarr:7878`

4. Configure Plex library roots.
Create or map libraries to:
- `/data/media/tv`
- `/data/media/movies`

5. Configure Overseerr.
Connect Plex using `http://<server-lan-ip>:32400`.
Then connect:
- Sonarr URL: `http://sonarr:8989`
- Radarr URL: `http://radarr:7878`

6. Configure Huntarr.
Connect Huntarr to:
- Sonarr URL: `http://sonarr:8989`
- Radarr URL: `http://radarr:7878`

Use missing-only mode and conservative schedules/rate limits.

## 9. Verify End-to-End Flow
1. Add a test movie/show request in Overseerr.
2. Confirm item appears in Sonarr/Radarr queue.
3. Confirm SABnzbd or qBittorrent receives the job.
4. Confirm import completes into `/data/media/...`.
5. Confirm Plex sees the new item.

## 10. Optional Service Allowlist
If you use the iptables allowlist helper:

```bash
cp /home/yob/media-stack/scripts/service-allowlist.conf.example /home/yob/media-stack/scripts/service-allowlist.conf
```
