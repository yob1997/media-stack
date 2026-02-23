# Huntarr config notes

Huntarr stores its settings in a SQLite database under /config/huntarr.db and writes logs
under /config/logs. There are no separate plaintext config files to template here.

Do not commit the DB, WAL/SHM files, or logs. Use the Huntarr UI to configure and let the
container create its own database at runtime.
