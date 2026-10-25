ARG CADDY_VERSION=2.11.7

FROM caddy:${CADDY_VERSION}-builder AS builder
ARG CADDY_VERSION
# ponytail: module has no tags yet, so track main; pin to a tag/SHA once released
ARG MODULE_VERSION=main
RUN apk add --no-cache vips-dev gcc musl-dev pkgconf
RUN CGO_ENABLED=1 xcaddy build v${CADDY_VERSION} \
    --with github.com/btafoya/caddy-image-optimizer@${MODULE_VERSION} \
    --output /usr/bin/caddy

# ponytail: runtime alpine must match the builder's alpine (vips ABI); bump together
FROM alpine:3.24
ARG CADDY_VERSION
RUN apk add --no-cache ca-certificates libcap mailcap vips \
    && mkdir -p /config/caddy /data/caddy /etc/caddy /srv \
    && chmod 1777 /config/caddy /data/caddy
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy \
    && caddy list-modules | grep -q http.handlers.image_optimizer
COPY Caddyfile /etc/caddy/Caddyfile

ENV XDG_CONFIG_HOME=/config XDG_DATA_HOME=/data
LABEL org.opencontainers.image.version=v${CADDY_VERSION} \
      org.opencontainers.image.source=https://github.com/btafoya/caddy-image-optimizer
EXPOSE 80 443 443/udp 2019
WORKDIR /srv
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
