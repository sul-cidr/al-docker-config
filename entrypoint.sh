#!/bin/bash
set -euxo pipefail;

# load the .env file
set -a && source .env && set +a;


CREATE_USER_PSQL="
DO \$\$
BEGIN
  CREATE ROLE ${DB_USER:?} WITH LOGIN SUPERUSER PASSWORD '${DB_PASSWORD:?}';
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
END
\$\$;";

CREATE_DB_PSQL="
CREATE EXTENSION IF NOT EXISTS dblink;
DO \$\$
BEGIN
  PERFORM dblink_exec('', 'CREATE DATABASE ${DATABASE:?}');
  EXCEPTION WHEN DUPLICATE_DATABASE THEN
  RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
END
\$\$;";

DB_ROOT_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}/postgres";
DATABASE_URL="postgresql://${DB_USER:?}:${DB_PASSWORD}@${DB_HOST}/${DATABASE}";


# Wait until the PostGIS server is accepting requests
#  (docker-compose's `depends_on` only waits till the container is up --
#   but the PostGIS container may not have completed its initialization)
until psql "${DB_ROOT_URL}" -c '\q' 2>/dev/null;
do
  >&2 echo "Waiting for PostGIS...";
  sleep 2;
done;


if [[ -n $(psql "${DATABASE_URL}" -c '\q' 2>&1) ]];
then
	# side-load the database dump
	psql "${DB_ROOT_URL}" --command="${CREATE_USER_PSQL}";
	psql "${DB_ROOT_URL}" --command="${CREATE_DB_PSQL}";
	bzcat "${APP_DIR}/authorial_final.sql.bz2" | psql "${DATABASE_URL}";
fi;

# Precompile assets
# (note: it would be much nicer to do this in a layer in the docker image, but a
#        connection to the db seems to be required to build the assets.
#        This also takes far longer than it seems it should, but... :shrug:).
if [[ ! -e public/.assets-built ]];
then
  RAILS_ENV=production DATABASE_URL="${DATABASE_URL}" bundle exec rake assets:precompile && touch public/.assets-built;
fi;

# the stylesheet compiled from app/assets/stylesheets/splash.scss references this file
#  without the hash -- on the old production server it was just copied into place, so
#  that's what I'm doing here, too...
cp public/assets/images/Grimshaw_Thames1880_adj01-0c1db9f25eb1987741e1e89baf7f0678.png public/assets/images/Grimshaw_Thames1880_adj01.png;

# Execute the container's main process
exec "$@"
