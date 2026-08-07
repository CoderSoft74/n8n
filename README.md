# n8n Self-Hosted — Instancia Principal

Instancia principal de n8n con PostgreSQL y node custom Whatsable para integración con WhatsApp.

## Arranque

```bash
docker-compose up -d
```

| Servicio | Puerto | Credenciales |
|----------|--------|-------------|
| n8n | 5678 | Ver `docker-compose.yml` |
| PostgreSQL | 5432 | Ver `docker-compose.yml` |

## Estructura de volúmenes

| Directorio | Montaje en container | Contenido |
|------------|---------------------|-----------|
| `n8ndata/` | `/home/node/.n8n` | Workflows, credenciales, base de datos, nodes custom |
| `postgresdata/` | `/var/lib/postgres/data` | Datos de PostgreSQL |

## Node custom instalado

**n8n-nodes-whatsable** v2.1.2 — integración con la API de Whatsable para envío/recepción de mensajes de WhatsApp.

Ubicación: `n8ndata/nodes/node_modules/n8n-nodes-whatsable/`

### Instalar otro node custom

```bash
cd n8ndata/nodes
npm install <nombre-del-node>
# Reiniciar n8n
docker-compose restart n8n
```

## Notas

- n8n usa PostgreSQL como backend (no SQLite)
- Las credenciales de la DB están configuradas via variables de entorno en `docker-compose.yml`
- Los archivos JSON de workflows en otros directorios son exports de n8n — importar desde la UI, no editar a mano
