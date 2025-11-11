# Ingesta de datos reales (fuentes oficiales)

Este documento describe **paso a paso** cómo construir los insumos en `data/` exclusivamente desde **archivos oficiales**. Formatos preferentes: **Parquet/Snappy**; salvaguarda: **CSV UTF‑8** (`.csv.gz`).

---

## 1) Volumen de control Gaia DR3 (TAP/ADQL)

**Cortes de calidad (Gaia DR3):** `parallax_over_error>10`, `ruwe<1.4`.

**Consultas por distancia (tres umbrales de paralaje):**

- 50 pc → `parallax > 20`
- 200 pc → `parallax > 5`
- 300 pc → `parallax > 3.3333333333333`

Use las consultas en `adql/gaia_dmax{50,200,300}pc.sql`. Ejecútelas en el TAP de Gaia (asíncrono **jobs**). Exportar como `gaia_subset.(parquet|csv)`.

**Notas TAP:**
- Modo **asíncrono** recomendado para conjuntos >100k filas.
- Use formato **CSV** o **Parquet** si el portal lo permite; de lo contrario, descargue CSV y convierta localmente.

---

## 2) AllWISE (cruce oficial en el archivo Gaia)

Obtenga el cruce **oficial** desde las tablas de Gaia DR3 hacia AllWISE:

- **Relación de cruce**: `gaiadr3.allwise_best_neighbour`
- **Tabla fotométrica**: `allwise.original_valid` *(o `allwise.main` según disponibilidad TAP)*

**Ejemplo (ADQL; genera `gaia_allwise_join`):**
```sql
SELECT g.source_id,
       g.ra, g.dec, g.parallax, g.parallax_over_error, g.pmra, g.pmdec, g.ruwe,
       g.teff_gspphot, g.phot_g_mean_mag,
       a.w1mpro, a.w1snr, a.w2mpro, a.w2snr, a.w3mpro, a.w3snr, a.w4mpro, a.w4snr,
       a.cc_flags, a.ext_flg
FROM user.gaia_subset AS g
JOIN gaiadr3.allwise_best_neighbour AS x
  ON x.source_id = g.source_id
JOIN allwise.original_valid AS a
  ON a.cntr = x.allwise_cntr
```
Exportar como `gaia_allwise_join.(parquet|csv)`.

---

## 3) CatWISE2020 (opcional; VizieR/XMatch)

Use el servicio **CDS XMatch** o VizieR (`II/365/catwise2020`) para recuperar W1/W2 más recientes.

**Estrategia:**
1. Suba `gaia_subset` con columnas `source_id, ra, dec`.
2. Cruce por radio (p.ej., 2″) contra `II/365/catwise2020`.
3. Seleccione campos clave: `designation`, `W1mpro`, `W2mpro`, `W1snr`, `W2snr`.
4. Guárdelo como `catwise_xmatch.(parquet|csv)`.

---

## 4) NEOWISE‑R (IRSA/IPAC) — variabilidad y robustez

Obtenga **medianas** y **σ** de W1/W2 por fuente desde **single‑exposure**:

- Tabla L1b típica: *NEOWISE‑R Single Exposure Source Table* (consulta por posición).
- Procedimiento:
  1. Para cada fuente (`ra, dec`), recupere medidas W1/W2 en un radio ~2″.
  2. Filtre por `qual_frame`, `saa_sep`, `cc_flags` compatibles, y S/N.
  3. Agregue por `designation`/posición: **mediana**, **desv. est.**, **N** válidos.
  4. Guarde `neowise_variability.(parquet|csv)` con columnas: `source_id`, `w1_median`, `w1_sigma`, `w1_n`, `w2_median`, `w2_sigma`, `w2_n`.

---

## 5) Regla de cobertura (W4)

Tras el cruce y limpieza inicial, calcule el porcentaje de fuentes con `w4snr≥5`.  
Si **% (w4snr≥5) < 30%**, repetir/centrar análisis con **d ≤ 200 pc** (modo *Focused*).

---

## 6) Registro de reproducibilidad

Incluya en su `data/README_LOCAL.md` (local):

- **ADQL exacta** utilizada (copiar/pegar).
- **URLs/DOI** de servicios: Gaia Archive TAP, CDS/VizieR, IRSA/IPAC.
- **Versiones** de productos (DR3, AllWISE release, CatWISE2020, NEOWISE‑R).
- **Fecha de descarga** y **tamaño** de ficheros.
