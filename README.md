# caddy-image-optimizer (Docker)

Caddy v2.11.7 built with [`btafoya/caddy-image-optimizer`](https://github.com/btafoya/caddy-image-optimizer) via [xcaddy](https://github.com/caddyserver/xcaddy). The module resizes and re-encodes JPEG, PNG and WebP images on demand and caches results on disk.

Image: `ghcr.io/btafoya/caddy-image-optimizer` (linux/amd64). Tags: `latest`, `v2.11.7`, and git tags.

## Quick start

```sh
mkdir site && cp photo.jpg site/
docker compose up -d
curl -H 'Accept: image/webp' -o out.webp 'http://localhost/photo.jpg?w=320&fmt=webp'
```

Or without compose:

```sh
docker run -d -p 80:80 -p 443:443 -p 443:443/udp \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile:ro \
  -v $PWD/site:/srv:ro \
  -v caddy_data:/data -v caddy_config:/config \
  ghcr.io/btafoya/caddy-image-optimizer:latest
```

## Request parameters

| Param | Meaning |
|-------|---------|
| `w`, `h` | Bounding box; aspect ratio kept, no upscaling |
| `q` | Quality, 1-100 |
| `fmt` | `jpg`, `png` or `webp` |
| `preset` | Named preset from the Caddyfile |

Malformed values return 400. Values outside the configured allowlists are rejected by default (`on_disallowed reject`). Clients that send `Accept: image/webp` get WebP.

## Caddyfile

The bundled `Caddyfile` is a working example:

```
{
	order image_optimizer before file_server
}

:80 {
	root * /srv
	image_optimizer {
		widths 320 640 960 1280
		qualities 40-90
	}
	file_server
}
```

`image_optimizer` must run before `file_server`. For all options (`presets`, `limits`, `cache_max_size`, `on_fail`, ...) see the [module README](https://github.com/btafoya/caddy-image-optimizer).

## Volumes

| Path | Purpose |
|------|---------|
| `/srv` | Web root (source images) |
| `/data` | Caddy data, TLS certs, and the optimizer cache (`/data/caddy/image_optimizer`) |
| `/config` | Caddy config |
| `/etc/caddy/Caddyfile` | Config (a default is baked in) |

Persist `/data`, otherwise the cache and certificates are lost on recreate. The cache is capped by `cache_max_size` (default 1GiB).

## Build

```sh
docker build -t caddy-image-optimizer .
```

| Build arg | Default | Notes |
|-----------|---------|-------|
| `CADDY_VERSION` | `2.11.7` | No `v` prefix; selects the `caddy:<ver>-builder` image |
| `MODULE_VERSION` | `main` | Module has no tags yet; use a tag or commit SHA to pin |

The build fails if `http.handlers.image_optimizer` is not in the resulting binary. The runtime `alpine` version must match the builder's Alpine (libvips ABI); bump both together.

## Limits

- No AVIF output.
- Animated GIF, APNG and animated WebP pass through unchanged.
- Runs as root, same as the official Caddy image.
- linux/amd64 only.

## CI

`.github/workflows/build.yml` builds and pushes to GHCR on push to `main` and on `v*` tags, using `GITHUB_TOKEN`.
