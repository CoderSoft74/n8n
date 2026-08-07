# CI/CD n8n — Auto GitLab Pipeline Generator

Instancia independiente de n8n que genera automáticamente pipelines `.gitlab-ci.yml` para proyectos GitLab que no tienen uno configurado.

## Flujo del Workflow

```
Cron (02:00 diario)
  -> Listar proyectos GitLab (activos en últimos 30 días)
  -> Listar ramas priorizadas (main, develop, staging, feature/*)
  -> Verificar si existe .gitlab-ci.yml
  -> Si NO existe (404):
      -> Escanear árbol de archivos del proyecto
      -> Detectar tipo (java-microservice, angular, react, docker, generic)
      -> Generar template CI/CD adecuado
      -> Crear archivo .gitlab-ci.yml vía API GitLab
      -> Disparar pipeline
  -> Enviar resumen por email
```

## Tipos de proyecto detectados

| Tipo | Indicadores |
|------|-------------|
| Java microservice | `pom.xml` + `Dockerfile` + `application.yml` |
| Java | `pom.xml` |
| Angular | `package.json` + `angular.json` |
| React | `package.json` |
| Docker | `Dockerfile` |
| Generic | Cualquier otro |

## Arranque

```bash
cd cicd_n8n
docker-compose up -d
```

n8n queda disponible en `http://localhost:5678`.

## Configuración

Editar `.env` con los valores reales antes de levantar:

| Variable | Descripción |
|----------|-------------|
| `GITLAB_URL` | URL de la instancia GitLab (default: `http://172.24.7.110`) |
| `GITLAB_TOKEN` | Personal Access Token de GitLab |
| `GITLAB_AUTO_MERGE_TOKEN` | Token para auto-merge (si se usa) |
| `SONAR_HOST_URL` | URL de SonarQube |
| `SONAR_TOKEN` | Token de SonarQube |
| `CI_SUMMARY_EMAIL` | Email destino del reporte diario |

## Notas

- Usa SQLite embebido (no requiere base de datos externa)
- El workflow viene **inactivo** — activarlo en la UI de n8n después de importar
- La imagen Docker es un build local (`docker.n8nio_n8n_latest:2.4`)
- Timezone del container: `America/Havana`
