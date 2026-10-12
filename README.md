# service-template

The standard shape for a service on the Zephyrus: its own GitHub repo, a Docker image, and a push-to-deploy pipeline. Foodbox, date-planner, transcriber and ai-hub all follow it.

```
git push -> CI (lint, tests, compose check, image build)
         -> CD: publish ghcr.io/zaher503/<name> -> self-hosted runner on the Zephyrus
                pulls it, restarts /opt/<name>, checks http://127.0.0.1:<port>/healthz
```

## New service in one command

```bash
scripts/new-service.sh recipes-api 8830
```

This creates the private repo `Zaher503/recipes-api` from this template, sets its name and port, registers a self-hosted runner for it on the Zephyrus (`/opt/actions-runner-recipes-api`), and creates `/opt/recipes-api`. Then put the service's real settings in `/opt/recipes-api/.env` on the Zephyrus (never in the repo) and push to `main`.

## What is in it

| File | Purpose |
|---|---|
| `Dockerfile` | Small Python image with a health check |
| `compose.yaml` | The stack as it runs on the Zephyrus (`restart: unless-stopped`, `.env`, one port). Join the shared `ai` network to use the AI hub |
| `.github/workflows/ci.yml` | Lint, tests, compose validation, image build (no push) |
| `.github/workflows/cd.yml` | Publish to GHCR, deploy through the runner, health check. Per service only `NAME`, `PORT` and the `runs-on` label change |
| `scripts/add-runner.sh` | Registers a per-repo GitHub Actions runner on the Zephyrus (a personal account cannot share one runner across repos) |
| `app/`, `tests/` | A `/healthz` stub to replace |

## Rules every service follows

- **The service must answer `GET /healthz`.** CD checks it after every deploy and fails the run if it never answers.
- **Secrets stay on the server** in `/opt/<name>/.env`, not in the repo. `.env.example` lists the names only.
- **Models and GPU work go through the AI hub** (`http://ai-hub:11434` on the Docker network `ai`): Ollama API for LLMs, `POST /v1/audio/transcriptions` for Whisper. Do not bundle an Ollama or Whisper in a service. The hub queues the work and returns `X-Queue-Position` / `X-Queue-Eta-Seconds`; show the wait in the UI. See https://github.com/Zaher503/ai-hub.
- **Data lives outside the container** under `/srv/<name>` (bind mount) or a named volume.
- **The README says where it runs and what it talks to**, so the next person (or Claude) can find the containers, ports, paths and neighbours without reading code.

## The services today

| Repo | Port | Talks to |
|---|---|---|
| [ai-hub](https://github.com/Zaher503/ai-hub) | 11434 | Owns Ollama and Whisper; creates the `ai` network |
| [foodbox](https://github.com/Zaher503/foodbox) | 8800 | ai-hub |
| [date-planner](https://github.com/Zaher503/date-planner) | 8820 | ai-hub, its own Postgres, Photon, OSRM, SearXNG |
| [transcriber](https://github.com/Zaher503/transcriber) | 8810 | ai-hub (Whisper) |
