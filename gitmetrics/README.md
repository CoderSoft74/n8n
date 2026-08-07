# GitMetrics — Productividad de Desarrolladores GitLab

Sistema de métricas de productividad que calcula horas estimadas de trabajo basándose en la dispersión temporal de commits.

## Arquitectura

```
GitLab (172.24.7.110)
  -> n8n (port 5678, cada 5 minutos)
    -> PostgreSQL (port 5432, schema: gitmetrics)
      -> Grafana (port 3000)
```

## Arranque

```bash
cd gitmetrics
docker-compose up -d
```

| Servicio | Puerto | Credenciales |
|----------|--------|-------------|
| PostgreSQL | 5432 | gitmetrics / gitmetrics |
| n8n | 5678 | admin / admin |
| Grafana | 3000 | admin / admin |

## Base de datos

Esquema `gitmetrics` con 6 tablas:

| Tabla | Propósito |
|-------|-----------|
| `projects` | Proyectos GitLab (upsert por `gitlab_id`) |
| `users` | Usuarios GitLab |
| `project_members` | Relación many-to-many proyecto-usuario |
| `commits` | Commits individuales |
| `merge_requests` | Merge requests |
| `daily_user_metrics` | Métricas diarias agregadas: commits, MRs, **horas estimadas** |

### Cálculo de horas estimadas

Las horas se calculan heurísticamente a partir de la dispersión de commits en el día. No es un tracking de tiempo real.

## Workflow n8n

**"GitLab Productividad Desarrolladores"** — se ejecuta cada 5 minutos:

1. Obtiene proyectos del GitLab
2. Para cada proyecto, en paralelo:
   - Upsert de proyectos
   - Obtener miembros -> upsert usuarios y relaciones
   - Obtener commits -> upsert -> calcular métricas diarias
   - Obtener merge requests -> upsert

### Credenciales a configurar

Importar el workflow y configurar en n8n:

- **GitLab Token** (HTTP Header Auth) — token de acceso personal de GitLab
- **PostgreSQL** — conexión a la db `gitmetrics`

## Dashboard Grafana

**"Productividad GitLab por Desarrollador"** — 3 paneles:

| Panel | Tipo | Descripción |
|-------|------|-------------|
| Métricas diarias por usuario | Tabla | Fecha, proyecto, commits, MRs, horas estimadas |
| Commits por usuario | Time series | Evolución temporal |
| Horas estimadas hoy | Bar chart | Ranking de horas por desarrollador |

## Notas

- El workflow usa placeholders `__REPLACE__...` en los IDs de credenciales — reemplazar después de importar
- `pgdata/` y `grafana-data/` son volúmenes de datos persistentes (no editar manualmente)
