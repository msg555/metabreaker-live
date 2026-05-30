#!/usr/bin/env bash

set -eo pipefail

site-hash() {
  find site/public/ -type f | sort | xargs -I{} sha256sum {} | sha256sum
}

SITE_HASH="<unset>"

aws s3 sync s3://metabreaker-live-data data/

PYTHONPATH=.
while true; do
  python -m mtgparse.process_manifest || true
	aws s3 sync data s3://metabreaker-live-data \
	  --cache-control "public,max-age=60"

  NEW_SITE_HASH=$(site-hash)
  if [ "${SITE_HASH}" != "${NEW_SITE_HASH}" ]; then
	  (
      cd site;
      wrangler pages deploy --commit-dirty=true \
          --project-name metabreaker-live --branch main
    )
  fi

  sleep 5m
done
