# SCHEDULED_TASKS

Archivos de configuración para tareas de MSBH recurrentes.

---

## Reinicios programados — `restart-schedule.json`

Cada entrada en `schedules` representa un reinicio único. 
El software verifica periódicamente este archivo, registra localmente los `id` ya procesados y agenda el reinicio a la hora indicada si el equipo aplica.

| Campo | Descripción |
|---|---|
| `id` | Identificador único. Formato recomendado: `restart-DD-MM-YYYY-###` |
| `target` | `"all"` para todos los equipos, o un array de hostnames específicos |
| `datetime` | Fecha y hora del reinicio en ISO 8601 |
| `reason` | Motivo del reinicio (informativo) |

```json
{
  "schedules": [
    {
      "id": "restart-2026-05-01-001",
      "target": "all",
      "datetime": "2026-05-01T23:00:00",
      "reason": "Mantenimiento mensual"
    },
    {
      "id": "restart-2026-05-01-002",
      "target": ["PC-CONTABILIDAD-01", "PC-RH-03"],
      "datetime": "2026-05-01T22:00:00",
      "reason": "Update de drivers"
    }
  ]
}
```
