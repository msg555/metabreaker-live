deploy-site:
	(cd site && wrangler pages deploy --project-name metabreaker-live --commit-dirty=false)

sync-data:
	aws s3 sync data s3://metabreaker-live-data \
	  --cache-control "public,max-age=60"

sync-data-local:
	(cd data && find -type f -printf "%P\n") | \
	  (cd site && xargs -I{} -- wrangler r2 object put metabreaker-live-data/{} --file=../data/{} --local)

dev-server:
	cd site && wrangler pages dev

format:
	black mtgparse/
	isort --profile black mtgparse/

lint:
	pylint mtgparse/

mypy:
	mypy --install-types mtgparse/

fly-set-secrets:
	@fly secrets set \
	  AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
	  AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
	  AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL}"

fly-stop-machine:
	fly machine stop "$(fly machine list -a 'metabreaker-live' -q)"

fly-start-machine:
	fly machine start "$(fly machine list -a 'metabreaker-live' -q)"

build-go:
	CGO_ENABLED=0 GOOS=linux go build -o calc_ranks calc_ranks.go
