#!/bin/bash
set -euxo pipefail;

# load the .env file
set -a && source .env && set +a;

cd "${APP_DIR}";

# Remove a potentially pre-existing server.pid for Rails.
rm -f "${APP_DIR}/tmp/pids/server.pid";

DATABASE_URL="postgresql://${DB_USER:?}:${DB_PASSWORD}@${DB_HOST}/${DATABASE}" passenger start;
