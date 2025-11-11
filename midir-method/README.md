# midir-method — Procedimiento reproducible de búsqueda de exceso térmico mid-IR (300–600 K)

**Resumen.** Este paquete proporciona un **método reproducible** para identificar **exceso térmico liso** (300–600 K) en el **mid‑IR** usando archivos públicos: **Gaia DR3**, **AllWISE** (vía cruce oficial en Gaia), **CatWISE2020** (opcional, VizieR/XMatch) y **NEOWISE‑R** (IRSA). Es **método‑primero**: incluye pipeline, modelos SED mínimos (M0/M1/M2), comparación bayesiana aproximada (BIC→lnZ), indicadores de calidad (**IWI**) y verificación con inyección‑recuperación sintética. **No** entrega un catálogo cosmológico ni resultados astrofísicos definitivos.

## Modos de ejecución

- **Lite (d ≤ 50 pc)**: validación y demo, ámbito local, |b|≥30°, <0.5 GB.
- **Focused (d ≤ 200 pc)**: cuando la **cobertura W4 con S/N≥5** es baja (<30%) o si se desea sensibilidad en W4 con un prior de detección.
- **Standard (d ≤ 300 pc)**: barrido general; particionar por HEALPix para escalar.

## Uso rápido

```bash
conda env create -f env.yml
conda activate midir-method
make demo
```

La demo consume `data/sample/*.csv` si no encuentra datos reales en `data/`.

## Estructura de datos esperados en `data/` (modo **Real**)

- `gaia_subset.(parquet|csv)`
- `gaia_allwise_join.(parquet|csv)`
- `catwise_xmatch.(parquet|csv)` *(opcional)*
- `neowise_variability.(parquet|csv)` *(opcional; estadísticos por fuente)*

Para generar estos insumos, siga **README_DATA.md** (ADQL exacta, fuentes y versiones oficiales).

## Referencia de modelos (usados en `src/`)

- **M0**: fotosfera estelar (BB efectivo) escalada.  
- **M1**: M0 + *greybody* (β∈[1,2]) + plantillas de silicato/PAH (opcional).  
- **M2**: M0 + BB liso (β=0) con \(T_w\in[250,800]\) K.

Selección por \(\Delta \ln Z \equiv -\tfrac{1}{2}(\mathrm{BIC}_{\rm M2}-\mathrm{BIC}_{\rm M0}) > 5\) y \(f_D\in[0.01,0.5]\). Consulte **docs/METHODS.md**.

## Créditos
Datos y marcas: ESA/Gaia, CDS/VizieR, IRSA/IPAC, WISE/NEOWISE; ver **LICENSE.md**.
