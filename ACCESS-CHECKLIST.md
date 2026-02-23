# Plex + WireGuard Access Checklist
Use this when giving a new person remote access to your media server.

## What They Need On Their Phone
- Install the `WireGuard` app.
- Install the `Plex` app.
- Create a personal `Plex` account (if they do not already have one).

## Owner Prerequisites (one-time)
- `wg-easy` is running and reachable on your LAN (`http://<server-lan-ip>:51821`).
- Router forwards `UDP 51820` to your server (`<server-lan-ip>:51820`).
- `wg-easy` `Host` is set to your public IP or DDNS hostname.

## Add A New Person
1. Ask for their Plex username or Plex account email.
2. In `wg-easy`, create a new client profile just for this person/device.
3. In the new client profile, set `Allowed IPs` to either `<server-lan-ip>/32` (Plex only) or `<home-lan-cidr>` (full home LAN).
4. Save and show the QR code in person, or securely share the config once.
5. In Plex Web as server owner: `Settings` -> `Manage Library Access` -> `Grant Library Access`.
6. Invite their Plex account and select which libraries they may access.
7. Have them accept the Plex invite from email or Plex notifications.

## New User Setup (Phone)
1. Open the WireGuard app.
2. Tap `+` and scan the QR code from `wg-easy`.
3. Turn the tunnel on.
4. Turn off Wi-Fi (force cellular test).
5. Open browser and test:
`http://<server-lan-ip>:32400/identity`
6. If XML appears, open Plex app and sign in with their own Plex account.
7. Confirm your server appears and libraries are visible.

## Verify It Works
- In `wg-easy`, confirm the client has a recent handshake and traffic counters increase.
- In Plex, confirm the invited user appears under shared users and can play media.

## Revoke Access Later
1. In `wg-easy`, disable or delete that person/device tunnel.
2. In Plex `Manage Library Access`, remove their share.
3. If needed, remove old device entries from Plex authorized devices.

## Security Notes
- Create one WireGuard profile per person/device. Do not share one profile.
- Do not expose `51821/tcp` (wg-easy web UI) to the internet.
- If a phone is lost, revoke WireGuard and Plex access immediately.
