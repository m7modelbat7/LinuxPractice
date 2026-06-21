#!/usr/bin/env bash

# ------------------------------------------------------------
# Project: Linux Users Exporter
# Purpose:
#   Read users from /etc/passwd, clean the data, save it as CSV,
#   and optionally import it into a PostgreSQL table.
#
# Author: Mahmoud Elbath
# ------------------------------------------------------------

set -euo pipefail

# Input file
PASSWD_FILE="${PASSWD_FILE:-/etc/passwd}"

# Output folder and file
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
CSV_FILE="${CSV_FILE:-$OUTPUT_DIR/linux_users.csv}"

# Set this to true if you want to import to PostgreSQL
IMPORT_TO_DB="${IMPORT_TO_DB:-false}"

echo "Starting Linux users export..."

# ------------------------------------------------------------
# 1. Basic checks
# ------------------------------------------------------------

if [ ! -f "$PASSWD_FILE" ]; then
    echo "Error: passwd file not found: $PASSWD_FILE"
    exit 1
fi

if [ ! -r "$PASSWD_FILE" ]; then
    echo "Error: passwd file is not readable: $PASSWD_FILE"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ------------------------------------------------------------
# 2. Extract and clean /etc/passwd data
# ------------------------------------------------------------
# /etc/passwd format:
# username:password:uid:gid:comment:home_directory:shell
#
# Example:
# root:x:0:0:root:/root:/bin/bash
# ------------------------------------------------------------

echo "Generating CSV file: $CSV_FILE"

awk -F: '
BEGIN {
    OFS=","
    print "username,uid,gid,full_name,home_directory,shell,account_type"
}

function csv(value) {
    gsub(/"/, "\"\"", value)
    return "\"" value "\""
}

{
    username = $1
    uid = $3
    gid = $4
    full_name = $5
    home_directory = $6
    shell = $7

    # Skip invalid rows
    if (username == "" || uid !~ /^[0-9]+$/ || gid !~ /^[0-9]+$/) {
        next
    }

    # Classify account type
    if (uid == 0) {
        account_type = "root_user"
    } else if (uid >= 1000 && uid < 65534) {
        account_type = "normal_user"
    } else {
        account_type = "system_user"
    }

    print csv(username), uid, gid, csv(full_name), csv(home_directory), csv(shell), csv(account_type)
}
' "$PASSWD_FILE" > "$CSV_FILE"

echo "CSV file created successfully."

# ------------------------------------------------------------
# 3. Optional PostgreSQL import
# ------------------------------------------------------------
# Required environment variables if IMPORT_TO_DB=true:
#
# export PGHOST="localhost"
# export PGPORT="5432"
# export PGDATABASE="linux_inventory"
# export PGUSER="postgres"
# export PGPASSWORD="your_password"
# export IMPORT_TO_DB=true
# ------------------------------------------------------------

if [ "$IMPORT_TO_DB" = "true" ]; then

    echo "PostgreSQL import is enabled."

    if ! command -v psql >/dev/null 2>&1; then
        echo "Error: psql command not found. Please install PostgreSQL client."
        exit 1
    fi

    : "${PGHOST:?Error: PGHOST is not set}"
    : "${PGPORT:?Error: PGPORT is not set}"
    : "${PGDATABASE:?Error: PGDATABASE is not set}"
    : "${PGUSER:?Error: PGUSER is not set}"
    : "${PGPASSWORD:?Error: PGPASSWORD is not set}"

    echo "Creating table if not exists..."

    psql -v ON_ERROR_STOP=1 -v csv_file="$CSV_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS linux_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    uid INT NOT NULL,
    gid INT NOT NULL,
    full_name TEXT,
    home_directory TEXT,
    shell TEXT,
    account_type VARCHAR(50),
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

TRUNCATE TABLE linux_users;

\copy linux_users(username, uid, gid, full_name, home_directory, shell, account_type) FROM :'csv_file' WITH (FORMAT csv, HEADER true);
SQL

    echo "Data imported successfully into PostgreSQL table: linux_users"

else
    echo "PostgreSQL import is disabled."
    echo "To enable it, run: export IMPORT_TO_DB=true"
fi

echo "Script completed successfully."