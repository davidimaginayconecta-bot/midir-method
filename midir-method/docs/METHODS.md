# MÉTODO: Búsqueda de exceso térmico liso mid‑IR (300–600 K)

## Objetivo
Detectar **exceso térmico liso** en el rango 300–600 K, compatible con emisión de *waste‑heat* o polvo templado, como **exceso sobre la fotosfera** en bandas WISE (W1–W4), priorizando **W3/W4**. El paquete entrega un **procedimiento reproducible** sin reclamar resultados astrofísicos finales.

## Flujo de datos (ingesta → resumen)
1. **Gaia DR3** → volumen de control con `parallax_over_error>10`, `ruwe<1.4` y umbral de paralaje (50/200/300 pc); columnas mínimas: `source_id, ra, dec, teff_gspphot, phot_g_mean_mag`.
2. **AllWISE** → cruce **oficial** mediante `gaiadr3.allwise_best_neighbour` y `allwise.original_valid`/`allwise.main`. Extraer: `w?mpro, w?snr, cc_flags, ext_flg`.
3. **CatWISE2020** *(opcional)* → W1/W2 recientes por XMatch (CDS/VizieR).
4. **NEOWISE‑R** → agregados por fuente (mediana, σ, N) en W1/W2 a partir de single‑exposure.

## Filtros de calidad (primera pasada)
- `cc_flags[W3]=='0' AND cc_flags[W4]=='0'`
- `ext_flg==0`
- `w3snr>=5 AND w4snr>=5`
- Excluir |b| < 8° en la primera pasada (minimiza confusión en plano galáctico).  
  *(Para ejecución Lite, puede omitirse el corte de |b| si no se dispone de b.)*

## Modelos SED
Denotemos \(B_\nu(\nu,T)\) la ley de Planck (frecuencia). Las predicciones se comparan con **flujos espectrales** por banda.

- **M0 (fotosfera)**: \(F_\nu = S_\star\,B_\nu(\nu,T_\star)\), donde \(T_\star\)≈`teff_gspphot`, y \(S_\star\) (escala) se ajusta.
- **M1 (fotosfera + greybody)**: \(F_\nu = S_\star B_\nu(\nu,T_\star) + S_d\,B_\nu(\nu,T_w)\,(\nu/\nu_0)^\beta\), \(\beta\in[1,2]\).
- **M2 (fotosfera + BB liso)**: \(F_\nu = S_\star B_\nu(\nu,T_\star) + S_d\,B_\nu(\nu,T_w)\) con \(\beta=0\), \(T_w\in[250,800]\) K.

### Ajuste y comparación
Se ajustan parámetros lineales (\(S_\star,S_d\)) por mínimos cuadrados ponderados en una **malla** de \(T_w\).
- \(\chi^2 = \sum_i \left[\frac{F^{\rm obs}_i - F^{\rm mod}_i}{\sigma_i}\right]^2\)
- \(\mathrm{BIC} = k\ln n + \chi^2\) con \(n\) puntos y \(k\) parámetros libres.
- \(\ln Z \approx -\tfrac{1}{2}\,\mathrm{BIC}\) (aprox. de Schwarz).
- **Criterio**: exceso aceptado si \(\Delta\ln Z \equiv \ln Z_{\rm M2}-\ln Z_{\rm M0} > 5\) **y** \(0.01 \le f_D \le 0.5\).

### Fracción de luminocidad del “waste” \(f_D\)
En el modelo lineal, una aproximación práctica:
\[
f_D \approx \frac{S_d}{S_\star}\left(\frac{T_w}{T_\star}\right)^4,
\]
ya que \(\int B_\nu\,d\nu \propto T^4\). Se **clampa** a \([10^{-6},1]\).

### Chequeo energético
Área emisora equivalente:
\[
A \equiv \frac{f_D\,L_\star}{\sigma T_w^4}.
\]
Descartar soluciones con \(f_D\) fuera de \([0.01,0.5]\) o que impliquen \(A\) implausible dados radios estelares razonables (no calculado por defecto en demo; se usa el rango de \(f_D\)).

## IWI — Índice de evidencia integrada
\[
\mathrm{IWI} = w_{\rm suav}\,S_{\rm suav} + w_{\beta0}\,S_{\beta=0} + w_{\rm var}\,S_{\rm var}
+ w_{\rm morf}\,S_{\rm morf} + w_{\rm ener}\,S_{\rm ener} + w_{\rm ctxt}\,S_{\rm ctxt},
\]
con pesos nominales \((0.30,0.25,0.15,0.10,0.10,0.10)\) **renormalizados a unidad** en el código.

**Definiciones de sub‑scores (0–1):**
- \(S_{\rm suav}\): suavidad espectral en W3–W4 (poca curvatura residual; p.ej. \(S=1-\mathrm{RMS}_{\rm res}/\mathrm{RMS}_{\rm obs}\) *clamp*).
- \(S_{\beta=0}\): preferencia BIC de M2 (β=0) frente a M1 (β>0); \(S=1\) si \(\Delta\mathrm{BIC}_{\rm M2-M1}<-10\), 0 si \(>0\), lineal intermedio.
- \(S_{\rm var}\): estabilidad NEOWISE‑R (mayor estabilidad ⇒ mayor score), p.ej. \(S=\exp(-\sigma_{\rm rel}^2)\).
- \(S_{\rm morf}\): morfología/limpieza AllWISE (`ext_flg=0`, `cc_flags[W3,W4]='0'` ⇒ 1, penalizaciones de lo contrario).
- \(S_{\rm ener}\): plausibilidad energética (1 si \(0.01\le f_D\le 0.5\)).
- \(S_{\rm ctxt}\): contexto; penaliza YSO/AGN/ULIRG o regiones complejas.

## Vetting / árbol de descarte (reglas)
1. **YSO/debris**: colores WISE en el diagrama clásico; si coincide con locus YSO y alta variabilidad → descartar/etiquetar.
2. **AGB/Mira**: amplitudes W1/W2 grandes y colores extremos.
3. **AGN/ULIRG**: colores `W1−W2>0.8` y `W2−W3` altos; coincidencia con catálogos extragalácticos.
4. **Blends/confusión**: `ext_flg>0`, `cc_flags` no nulos, inspección unWISE (si disponible).

## Validación sintética (inyección–recuperación)
- Construir 100 fuentes **M2** con \(T_w\in[300,600]\) K y \(f_D\in[0.01,0.3]\); añadir ruido fotométrico gaussiano equivalente a **±0.03 mag**.
- Construir 100 fuentes **control** M0/M1.
- Métricas: **recall** a \(\Delta\ln Z>5\) y \(f_D\) en rango; **FPR** objetivo < 10%.

## Rutas de ejecución (Lite / Focused / Standard)
- **Lite (≤50 pc)**: demo, sin *tiling*.  
- **Focused (≤200 pc)**: cuando W4 falte, prior W4 (re‑ejecutar NEOWISE forzado si procede).  
- **Standard (≤300 pc)**: **sharding HEALPix** (NSIDE configurable, p.ej. 64). Manifest: lista de *tiles* con conteo y métricas de cobertura para reparto comunitario (ver `docs/REPLICATION_CALL.md`).
