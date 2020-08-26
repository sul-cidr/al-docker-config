# al-docker-config

This repo contains docker configuration and secrets needed to deploy the Authorial London project (from https://github.com/sul-cidr/al).  The public site is available at http://authorial.stanford.edu, and the deployment is on `cidr-authorial-prod`.

The configuration runs containers for the Authorial London Rails app and a PostGIS server, and exposes the Rails app via a standalone Passenger server on port 3000 of the host (with the intention that this then be reverse-proxied by Apache or NGINX).  On `cidr-authorial-prod` it's behind an Apache install (and SSL cert config etc.) managed via puppet by DLSS.

I've tried to touch the orignal repo (at `sul-cidr/al`), and in particular the code, as little as possible.  Some things (like the use of the passenger gem) are implemented in the configuration files here that could perhaps be incorporated into the upstream repo.  Likewise the capistrano config there is now redundant (the gems aren't by this config, but even so).

Configuration variables are in the `.env` file -- edit as required.  Production secrets are in this repo, so keep it private (they were previously in the `cidr-authorial` branch of the private `sul-dlss/shared_configs` repo at https://github.com/sul-dlss/shared_configs/tree/cidr-authorial).

To get this up and going, make sure you have docker engine and docker-compose installed, then clone the repo, edit `.env` values as and if desired, and run `docker compose up -d`.

To redeploy with updated source from GitHub, do `docker-compose down && docker-compose up --build` to rebuild the image with the modified source from the `master` branch of the repo at `sul-cidr/al`.

