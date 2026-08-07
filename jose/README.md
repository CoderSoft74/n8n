# Jose — GitLab Metrics Pipeline

Pipeline completo de métricas de desarrolladores GitLab con sistema de alertas. Diseñado para el instance de Jose.

## Componentes

| Archivo | Tipo | Propósito |
|---------|------|-----------|
| `gitlab_jose.sql` | SQL | Esquema de base de datos completo |
| `workflow_n8n.json` | n8n | Workflow de recolección y alertas |
| `grafana.json` | Grafana | Dashboard de visualización |

## Esquema de base de datos

Base de datos: `gitlab_metrics` (crear manualmente antes de ejecutar el SQL).

| Tabla | Propósito |
|-------|-----------|
| `projects` | Proyectos GitLab |
| `users` | Usuarios/desarrolladores |
| `commit_metrics` | Métricas por commit: calidad de mensaje, additiones/deleciones, detección de merge/revert, refs a issues/MRs |
| `commit_files` | Archivos modificados por commit |
| `daily_metrics` | Métricas diarias agregadas |
| `weekly_metrics` | Métricas semanales |
| `alert_thresholds` | Umbrales configurables para alertas |
| `alerts` | Alertas generadas |

### Alertas por defecto

| Métrica | Mín | Máx | Severidad |
|---------|-----|-----|-----------|
| commit_frequency | 2 | 10 | warning |
| commit_size_loc | 50 | 300 | warning |
| revert_rate | - | 5% | critical |
| active_days_ratio | 60% | 80% | info |
| issue_linked_commits | 80% | - | warning |

## Workflow n8n

**"GitLab Metrics Monitor"** — cada 6 horas:

1. Obtener proyectos de GitLab (`http://172.24.7.110/api/v4/projects`)
2. Para cada proyecto, obtener commits de los últimos 7 días
3. Enriquecer datos: calidad de mensaje, detección de reverts, refs a issues/MRs, clasificación horario laboral
4. Calcular métricas agregadas por usuario/proyecto
5. Upsert en `daily_metrics`
6. Evaluar alertas:
   - **Revert rate > 5%** → alerta crítica
   - **Calidad de mensajes < 80%** → warning

### Credenciales

- **GitLab Token** (HTTP Header Auth)
- **PostgreSQL Metrics** (conexión a `gitlab_metrics`)

## Dashboard Grafana

**"GitLab Metrics Dashboard"** — auto-refresh 5 minutos:

| Panel | Tipo | Descripción |
|-------|------|-------------|
| Resumen General | Stat | Total commits últimos 30 días |
| Calidad de Mensajes | Gauge | % de mensajes >= 15 chars (rojo < 70, amarillo 70-90, verde > 90) |
| Top Contribuyentes | Tabla | Top 10 por commits con additions/deletions |
| Evolución de Commits | Time series | Tendencia 90 días |
| Alertas Activas | Tabla | Alertas resueltas de los últimos 7 días |

## Setup

```sql
-- 1. Crear la base de datos
CREATE DATABASE gitlab_metrics;

-- 2. Ejecutar el esquema
\c gitlab_metrics
\i gitlab_jose.sql
```

```bash
# 3. Importar workflow en n8n UI
# 4. Importar dashboard en Grafana (Settings -> Import -> Upload JSON)
```

## Notas

- El workflow usa `http://172.24.7.110` como instancia GitLab target
- Los archivos SQL crean la DB — ejecutar solo una vez
- El dashboard y workflow están diseñados para trabajar juntos con el mismo esquema
