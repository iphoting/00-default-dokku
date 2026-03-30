# CLAUDE.md — AI Assistant Guide for 00-default-dokku

## Overview

Catch-all default Dokku application that returns **HTTP 410 Gone** for every route.
Serves as the default vhost on the Dokku host so that unknown domains receive a
well-formed error response instead of a Dokku splash page.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Ruby version | 3.4.9 (see `.ruby-version`) |
| Web framework | Sinatra |
| Production server | Iodine (via Rack) |
| Development server | WEBrick (via Rack) |
| Container base | `ruby:3.4.9-slim` (Debian) |

---

## Repository Layout

```
00-default-dokku/
├── .github/workflows/
│   ├── docker.yml        # CI: build image + HTTP 410 smoke test
│   └── dokku.yaml        # CD: deploy to Dokku on push to master/dokku
├── config.ru             # Sinatra app — returns 410 for all routes
├── Dockerfile            # Multi-stage Docker build
├── Gemfile               # Ruby gem dependencies
├── Gemfile.lock          # Locked gem versions
├── Procfile              # Dokku process definition
├── .ruby-version         # Pinned Ruby version
└── .dockerignore         # Docker build context exclusions
```

---

## Application Logic

`config.ru` is the entire application:

```ruby
require 'sinatra'

get '/**' do
  status 410
end

run Sinatra::Application
```

All `GET` requests to any path return `410 Gone`. No templates, assets, or
additional routes.

---

## Development Workflow

### Setup

```bash
bundle install
```

### Run locally

```bash
bundle exec rackup          # WEBrick on port 9292 (development)
bundle exec iodine -p 9292  # Iodine (production-like)
```

Verify: `curl -o /dev/null -w "%{http_code}" http://localhost:9292/` should return `410`.

### Docker

```bash
docker build -t 00-default .
docker run -p 9292:9292 00-default bundle exec rackup -o 0.0.0.0
```

The Dockerfile uses a **multi-stage build**:
1. **Builder stage**: installs build tools, installs gems into `vendor/`
2. **Runtime stage**: copies `vendor/` from builder; no build tools in final image

---

## CI/CD Pipelines

### GitHub Actions

**`docker.yml`** — runs on every push and pull request:
- Builds Docker image
- Starts container on port 9292
- Polls until ready, then asserts HTTP 410 response

**`dokku.yaml`** — runs on pushes to `master` or `dokku`/`dokku**` branches:
- Deploys to Dokku server: `ssh://dokku@c.iphoting.cc:3022/00-default-dokku`
- Uses `SSH_PRIVATE_KEY` secret
- Force-push enabled; in-progress runs cancelled by concurrency control

---

## Dependency Management

Gem versions are locked in `Gemfile.lock`. To update:

```bash
bundle update
```

Then commit both `Gemfile.lock` and (if changed) `.ruby-version`.

When bumping the Ruby version:
1. Update `.ruby-version`
2. Update `RUBY VERSION` in `Gemfile.lock`
3. Update `FROM ruby:X.Y.Z-slim` in `Dockerfile` (both stages)
4. Remove any platform entries in `Gemfile.lock` that no longer apply

---

## Code Conventions

### Commit Messages

Follow **Conventional Commits** style:

```
<type>: <short description>

Types: feat, fix, chore, ci, docs, refactor
Examples: chore(deps): bump sinatra, ci: add smoke test timeout
```

---

## Deployment

| Target | Trigger | Method |
|---|---|---|
| Dokku (primary) | Push to `master`/`dokku` branch | `dokku.yaml` GitHub Action force-push |

---

## Important Notes

- This app intentionally has **no content** — its sole purpose is the 410 response.
  Do not add routes, templates, or assets.
- The `Procfile` runs Iodine in production: `web: bundle exec iodine -p ${PORT}`.
  Dokku sets `$PORT` automatically.
- Ruby version must match `.ruby-version` exactly. Use `rbenv` or `rvm` locally.
- The smoke test CI expects **exactly HTTP 410**. Any change to the response code
  will fail CI.
