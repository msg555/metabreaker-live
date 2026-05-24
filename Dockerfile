FROM python:3.12-slim AS source_image

# --------------------------------------------
FROM source_image AS aws_installer

RUN apt-get update && \
    apt-get install -y curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /out \
 && cd /out \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip \
 && unzip awscliv2.zip \
 && rm awscliv2.zip


# --------------------------------------------
FROM golang:1.24-alpine AS calc_ranks_builder

COPY calc_ranks.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o calc_ranks calc_ranks.go \
 && mkdir /out \
 && mv calc_ranks /out/


# --------------------------------------------
FROM source_image AS target

COPY --from=aws_installer /out/ /aws/

RUN /aws/aws/install && rm -rf /aws

WORKDIR /work

COPY requirements.txt ./

RUN pip install -r requirements.txt

COPY --from=calc_ranks_builder /out/calc_ranks ./

RUN mkdir -p cache data/ranks site/public/

COPY mtgparse ./mtgparse
COPY update_loop.sh manifest.yaml ./

# TODO: Make cache have folder per tournament and prune inactive cache for
# inactive tournaments on startup.

CMD ["./update_loop.sh"]
