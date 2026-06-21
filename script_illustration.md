# Linux Users Exporter

A simple Linux shell scripting project for practicing real system administration commands.

This project reads user account data from `/etc/passwd`, extracts important fields, cleans the data, saves it into a CSV file, and can optionally import the result into a PostgreSQL table.

## Project Goal

The goal of this project is to practice Linux commands in a practical way instead of only memorizing commands.

In this project, I used:

* Bash scripting
* Linux file checks
* `/etc/passwd`
* `awk`
* CSV formatting
* Environment variables
* PostgreSQL `psql`
* Git and GitHub

## Business Benefit

This script can help system administrators collect Linux user information automatically.

Instead of checking users manually on every server, the script can export the users into a clean CSV file and optionally store them in PostgreSQL.

This is useful for auditing, reporting, security review, reducing manual work, and reducing human mistakes.

## How to Run

Make the script executable:

```bash
chmod +x scripts/export_passwd_users.sh
```

Run the script:

```bash
./scripts/export_passwd_users.sh
```

The CSV file will be created here:

```text
output/linux_users.csv
```

## PostgreSQL Import

Set the database variables:

```bash
export PGHOST="localhost"
export PGPORT="5432"
export PGDATABASE="linux_inventory"
export PGUSER="postgres"
export PGPASSWORD="your_password"
export IMPORT_TO_DB=true
```

Run the script again:

```bash
./scripts/export_passwd_users.sh
```

## Script Explanation

### `#!/usr/bin/env bash`

This tells Linux to run the script using Bash.

### `set -euo pipefail`

This makes the script safer:

* `-e`: stop if any command fails
* `-u`: stop if a variable is missing
* `pipefail`: stop if a command inside a pipe fails

### `PASSWD_FILE="${PASSWD_FILE:-/etc/passwd}"`

This defines the input file. By default, it reads `/etc/passwd`.

### `OUTPUT_DIR="${OUTPUT_DIR:-./output}"`

This defines the output folder.

### `CSV_FILE="${CSV_FILE:-$OUTPUT_DIR/linux_users.csv}"`

This defines the CSV output file.

### `IMPORT_TO_DB="${IMPORT_TO_DB:-false}"`

This controls whether PostgreSQL import is enabled or disabled.

### File Checks

```bash
if [ ! -f "$PASSWD_FILE" ]; then
```

This checks if the file exists.

```bash
if [ ! -r "$PASSWD_FILE" ]; then
```

This checks if the file is readable.

### `mkdir -p "$OUTPUT_DIR"`

This creates the output directory if it does not already exist.

### `awk -F:`

This starts the `awk` command and uses `:` as the separator because `/etc/passwd` is colon-separated.

Example:

```text
root:x:0:0:root:/root:/bin/bash
```

Fields:

| Field | Meaning           |
| ----- | ----------------- |
| `$1`  | Username          |
| `$3`  | UID               |
| `$4`  | GID               |
| `$5`  | Full name/comment |
| `$6`  | Home directory    |
| `$7`  | Shell             |

### `BEGIN`

The `BEGIN` block runs before reading the file. It prints the CSV header.

### `csv(value)`

This function cleans text values and wraps them in double quotes for CSV format.

### Field Extraction

```awk
username = $1
uid = $3
gid = $4
full_name = $5
home_directory = $6
shell = $7
```

This extracts the useful fields from `/etc/passwd`.

### Validation

```awk
if (username == "" || uid !~ /^[0-9]+$/ || gid !~ /^[0-9]+$/) {
    next
}
```

This skips invalid rows.

### Account Classification

```awk
if (uid == 0) {
    account_type = "root_user"
} else if (uid >= 1000 && uid < 65534) {
    account_type = "normal_user"
} else {
    account_type = "system_user"
}
```

This classifies users into root, normal user, or system user.

### PostgreSQL Import

The script checks if `psql` exists, checks the required database variables, creates the table, clears old data, and imports the CSV.

## Interview Summary

I built a Bash script that reads `/etc/passwd`, checks that the file exists and is readable, extracts useful fields using `awk`, cleans the data into CSV format, and optionally imports it into PostgreSQL.

I used safety options like `set -euo pipefail`, validation checks, environment variables, and PostgreSQL `psql`.

The business benefit is that this script automates Linux user inventory collection, which helps in auditing, reporting, and reducing manual work.
::: 
