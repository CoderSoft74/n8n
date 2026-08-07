# AGENTS.md

## Repository Purpose

Infrastructure and workflow repository for self-hosted n8n instances. Contains Docker Compose deployments, exported n8n workflow JSONs, Grafana dashboards, and custom nodes.

## Directory Structure

- `docker-compose.yml` — Main n8n + PostgreSQL deployment (port 5678)
- `cicd_n8n/` — CI/CD n8n instance with its own Docker Compose and workflow exports
- `gitlab_metrics/` — GitLab metrics collection: n8n workflows, Grafana dashboards, credentials
- `gitmetrics/` — Git metrics instance with PostgreSQL init scripts and Grafana config
- `jose/` — Jose-specific setup: SQL scripts, Grafana dashboard, n8n workflow
- `n8ndata/` — n8n persistent data volume (contains custom nodes under `nodes/`)
- `postgresdata/` — PostgreSQL data volume (mounted by main Docker Compose)

## Key Facts

- Main n8n runs on port 5678 with basic auth (configurar en `docker-compose.yml`)
- Custom node `n8n-nodes-whatsable` installed in `n8ndata/nodes/node_modules/`
- Workflow JSON files are n8n exports — edit in n8n UI, not by hand
- Grafana dashboards are JSON exports — importable via Grafana API or UI

## Conventions

- Each subdirectory is a semi-independent n8n environment or tool
- Docker Compose files mount local data volumes for persistence
- Workflow and dashboard JSONs are snapshots, not source-of-truth (n8n/Grafana UI is)
