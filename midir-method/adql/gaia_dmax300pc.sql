-- Gaia DR3 — Volumen de control d ≤ 300 pc (parallax > 3.333... mas)
-- TAP asíncrono, exportación a CSV/Parquet. Mantener mismas columnas.
SELECT source_id, ra, dec, parallax, parallax_over_error,
       pmra, pmdec, ruwe, teff_gspphot, phot_g_mean_mag
FROM gaiadr3.gaia_source
WHERE parallax_over_error > 10
  AND ruwe < 1.4
  AND parallax > 3.3333333333333335
