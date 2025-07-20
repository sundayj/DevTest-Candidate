#!/bin/sh
set -e

apt-get update
apt-get install -y postgresql

# Update the default port for all clusters
for CONF in /etc/postgresql/*/main/postgresql.conf; do
    sed -ri "s/^#?port\s*=\s*[0-9]+/port = 5433/" "$CONF"
done

# Set PGPORT so client tools use the same port
echo "export PGPORT=5433" > /etc/profile.d/pgport.sh

# Start all available PostgreSQL clusters. The base image may install
# different versions depending on the distribution, so avoid hardcoding
# the version number.
service postgresql start

# Update pg_hba.conf to use md5 authentication for local and TCP/IP connections
PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")
sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$PG_HBA"
sudo sed -i 's/^host\s\+all\s\+all\s\+127.0.0.1\/32\s\+scram-sha-256/host    all             all             127.0.0.1\/32            md5/' "$PG_HBA"
sudo sed -i 's/^host\s\+all\s\+all\s\+::1\/128\s\+scram-sha-256/host    all             all             ::1\/128                 md5/' "$PG_HBA"

# Reload PostgreSQL to apply changes
sudo service postgresql reload

# Create database, user, and set password if not exist
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

if [ "$DB_USER" = "postgres" ]; then
  sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_PASSWORD';"
else
  sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$DB_USER') THEN
      CREATE USER "$DB_USER" WITH PASSWORD '$DB_PASSWORD';
   END IF;
END
\$do\$;
EOF
fi

sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
      CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";
   END IF;
END
\$do\$;
EOF
