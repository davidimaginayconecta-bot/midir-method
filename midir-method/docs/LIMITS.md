# Límites poblacionales cuando no hay candidatos

Si no se detectan candidatos que cumplan \(\Delta\ln Z>5\) y \(0.01\le f_D\le 0.5\), se puede reportar un **límite** sobre la fracción poblacional \(\mathcal{F}(>f_D; T_w)\) bajo supuestos de cobertura y pureza.

## Supuestos
- Muestra de \(N\) estrellas con **cobertura válida** (p.ej., `w3snr≥5 & w4snr≥5`, `ext_flg=0`, `cc_flags` limpios).
- Eficiencia de detección \(\epsilon(f_D,T_w)\) estimada por inyección–recuperación (±0.03 mag).
- Contaminación residual \(<\) FPR objetivo (10%).

## Cota (Poisson/Binomial)
Con \(k=0\) detecciones y \(N_{\rm eff}=\sum_i \epsilon_i\), una cota conservadora al 95% CL:
\[
\mathcal{F}(>f_D;T_w) \lesssim \frac{3}{N_{\rm eff}}.
\]
Si \(\epsilon\) es aproximadamente constante:
\[
\mathcal{F}(>f_D;T_w) \lesssim \frac{3}{N\,\epsilon(f_D,T_w)}.
\]

## Cobertura de calidad
Reportar:
- % con `w4snr≥5`.
- Fracción con `cc_flags[W3,W4]='0'`, `ext_flg=0`.
- Distribución de \(|b|\) de la muestra.
- Rango de \(T_\star\) considerado y cualquier exclusión.

## Presentación
Entregar tabla de límites \(\mathcal{F}\) vs. \(T_w\) y \(f_D\) (rejilla), citando su **pipeline**, versión del **repo** y fecha.
