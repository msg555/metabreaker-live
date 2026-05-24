#!/usr/bin/env bash

set -eo pipefail

PYTHONPATH=.
while true; do
  python -m mtgparse.process_manifest || true
	aws s3 sync data s3://metabreaker-live-data \
	  --cache-control "public,max-age=60"
  sleep 5m
done
