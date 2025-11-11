# Convocatoria abierta de replicación (HEALPix)

Invitamos a la comunidad a **replicar** y **escalar** el método. Ofrecemos un esquema de co‑autoría basado en contribuciones por *tiles* HEALPix.

## Tareas ofrecidas
- Ingesta y limpieza (Gaia→AllWISE→CatWISE/NEOWISE).
- Ejecución del pipeline (M0/M2, BIC→lnZ, IWI).
- Validación sintética (inyección–recuperación).
- Revisión de vetting manual en outliers.

## Cómo reclamar un tile
- Definimos un **manifest** por HEALPix (p.ej., NSIDE=64) con: `tile_id`, centroides, nº de fuentes, %W4 S/N≥5.
- Solicite un `tile_id` libre (issue/pull request).
- Tras asignación, ejecute el pipeline para ese tile y suba artefactos.

## Entrega de artefactos mínimos
- `results/tile_{id}/candidates.parquet` (o `.csv.gz`) con métricas (ΔlnZ, f_D, IWI, flags).
- `results/tile_{id}/summary.json` (cobertura, %W4 S/N≥5, recuentos).
- `logs/tile_{id}.txt` con versión de repo y fecha.

## Criterios de co‑autoría
- ≥ 1 tile completo + entrega validada.
- Evidencia de reproducción (hash de datos, commit del repo).
- Aceptación de normas de estilo y documentación.

## Contacto
- Abra un **issue** con su propuesta y afiliación.
- Para dudas técnicas, use la categoría “method‑support” en issues.
