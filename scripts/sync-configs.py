#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path
from typing import Any
import xml.etree.ElementTree as ET

SOURCE_ROOT = Path("/data/config")
REPO_ROOT = Path(__file__).resolve().parents[1]
DEST_ROOT = REPO_ROOT / "data" / "config"

REDACTED = "__REDACTED__"

SENSITIVE_XML_TAGS = {
    "apikey",
    "accesskey",
    "accesstoken",
    "refreshtoken",
    "password",
    "passphrase",
    "secret",
    "cookie",
    "sslcertpassword",
}

SENSITIVE_JSON_KEY_SUBSTRINGS = [
    "apikey",
    "api_key",
    "token",
    "secret",
    "password",
    "passphrase",
    "cookie",
    "clientid",
    "client_id",
    "machineid",
    "nzbkey",
    "nzb_key",
    "vapidprivate",
    "vapidpublic",
]

SENSITIVE_JSON_KEYS = {
    "ip",
}

JSON_KEY_REPLACEMENTS = {
    "ip": "__PLEX_SERVER_IP__",
}

SENSITIVE_INI_KEYS = {
    "api_key",
    "nzb_key",
    "username",
    "password",
    "email_pwd",
    "email_account",
    "email_server",
    "socks5_proxy_url",
}

INI_KEY_REPLACEMENTS = {
    "host_whitelist": "sabnzbd, wireguard, localhost, 127.0.0.1, __SERVER_LAN_IP__, __TRUSTED_CLIENT_IP__",
}


def log(message: str) -> None:
    print(message)


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def redact_xml(source: Path, dest: Path) -> None:
    tree = ET.parse(source)
    root = tree.getroot()

    for elem in root.iter():
        tag = (elem.tag or "").lower()
        if tag in SENSITIVE_XML_TAGS:
            elem.text = REDACTED

    ensure_parent(dest)
    tree.write(dest, encoding="utf-8", xml_declaration=False)
    log(f"Wrote {dest}")


def _is_sensitive_json_key(key: str) -> bool:
    key_lower = key.lower()
    if key_lower in SENSITIVE_JSON_KEYS:
        return True
    return any(token in key_lower for token in SENSITIVE_JSON_KEY_SUBSTRINGS)


def redact_json_value(value: Any) -> Any:
    if isinstance(value, dict):
        new_obj = {}
        for k, v in value.items():
            key_lower = k.lower()
            if key_lower in JSON_KEY_REPLACEMENTS:
                new_obj[k] = JSON_KEY_REPLACEMENTS[key_lower]
            elif _is_sensitive_json_key(k):
                new_obj[k] = REDACTED if isinstance(v, str) else ""
            else:
                new_obj[k] = redact_json_value(v)
        return new_obj
    if isinstance(value, list):
        return [redact_json_value(v) for v in value]
    return value


def redact_json(source: Path, dest: Path) -> None:
    data = json.loads(source.read_text())
    redacted = redact_json_value(data)
    ensure_parent(dest)
    dest.write_text(json.dumps(redacted, indent=2))
    log(f"Wrote {dest}")


def redact_ini(source: Path, dest: Path) -> None:
    lines = source.read_text().splitlines()
    redacted_lines = []

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith(";") or stripped.startswith("#"):
            redacted_lines.append(line)
            continue

        if "=" not in line:
            redacted_lines.append(line)
            continue

        key, _ = line.split("=", 1)
        key_name = key.strip().lower()
        if key_name in INI_KEY_REPLACEMENTS:
            redacted_lines.append(f"{key.strip()} = {INI_KEY_REPLACEMENTS[key_name]}")
        elif key_name in SENSITIVE_INI_KEYS:
            redacted_lines.append(f"{key.strip()} = {REDACTED}")
        else:
            redacted_lines.append(line)

    ensure_parent(dest)
    dest.write_text("\n".join(redacted_lines) + "\n")
    log(f"Wrote {dest}")


def copy_file(source: Path, dest: Path) -> None:
    ensure_parent(dest)
    shutil.copy2(source, dest)
    log(f"Copied {dest}")


def main() -> int:
    if not SOURCE_ROOT.exists():
        log(f"Source config root not found: {SOURCE_ROOT}")
        return 1

    tasks = [
        (SOURCE_ROOT / "radarr" / "config.xml", DEST_ROOT / "radarr" / "config.xml.example", "xml"),
        (SOURCE_ROOT / "sonarr" / "config.xml", DEST_ROOT / "sonarr" / "config.xml.example", "xml"),
        (SOURCE_ROOT / "prowlarr" / "config.xml", DEST_ROOT / "prowlarr" / "config.xml.example", "xml"),
        (SOURCE_ROOT / "sabnzbd" / "sabnzbd.ini", DEST_ROOT / "sabnzbd" / "sabnzbd.ini.example", "ini"),
        (SOURCE_ROOT / "overseerr" / "settings.json", DEST_ROOT / "overseerr" / "settings.json.example", "json"),
    ]

    for source, dest, kind in tasks:
        if not source.exists():
            log(f"Skip missing {source}")
            continue

        if kind == "xml":
            redact_xml(source, dest)
        elif kind == "json":
            redact_json(source, dest)
        elif kind == "ini":
            redact_ini(source, dest)
        else:
            raise ValueError(f"Unknown kind: {kind}")

    # Optional overrides
    override_src = SOURCE_ROOT / "overseerr" / "overrides" / "plextv.js"
    override_dest = DEST_ROOT / "overseerr" / "overrides" / "plextv.js"
    if override_src.exists():
        copy_file(override_src, override_dest)

    return 0


if __name__ == "__main__":
    sys.exit(main())
