FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.4.0 AS cross-compile
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build

RUN apk add --update clang lld
ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

COPY --from=cross-compile / /
WORKDIR /go/src/app
ENV CGO_ENABLED=1 \
  GOCACHE=/cache/go \
  GOMODCACHE=/cache/gomod

RUN <<-EOF
  go env -w GOCACHE=${GOCACHE}
  go env -w GOMODCACHE=${GOMODCACHE}
  xx-apk add --update musl-dev gcc
EOF

RUN --mount=type=bind,source=go.mod,target=/go/src/app/go.mod,readonly \
  --mount=type=bind,source=go.sum,target=/go/src/app/go.sum,readonly \
  --mount=type=cache,target=${GOCACHE} \
  --mount=type=cache,target=${GOMODCACHE} \
  --mount=type=cache,target=/go/pkg \
  xx-go mod download -x

RUN --mount=type=bind,source=.,target=/go/src/app,readonly \
  --mount=type=cache,target=${GOCACHE} \
  --mount=type=cache,target=${GOMODCACHE} \
  --mount=type=cache,target=/go/pkg \
  xx-go build -a --ldflags="-linkmode=external -extldflags='-static'" -trimpath -o /go/bin/app ./cmd/migrate \
  && xx-verify --static /go/bin/app

FROM alpine:3.20 AS main
RUN apk add --no-cache ca-certificates
USER nobody
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=build /go/bin/app /migrate
ENTRYPOINT ["/docker-entrypoint.sh"]
