-- Gaia DR3 — Volumen de control d ≤ 50 pc (parallax > 20 mas)
-- Modo recomendado: TAP asíncrono (jobs). Exportar a CSV/Parquet.
-- Sugerencia: limitar columnas a lo necesario para cruce y SED.
SELECT source_id, ra, dec, parallax, parallax_over_error,
       pmra, pmdec, ruwe, teff_gspphot, phot_g_mean_mag
FROM gaiadr3.gaia_source
WHERE parallax_over_error > 10
  AND ruwe < 1.4
  AND parallax > 20
