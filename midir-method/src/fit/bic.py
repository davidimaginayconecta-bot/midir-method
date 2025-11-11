from __future__ import annotations
import numpy as np

def chi2(obs, mod, sigma):
    obs = np.asarray(obs, float)
    mod = np.asarray(mod, float)
    sigma = np.asarray(sigma, float)
    m = np.isfinite(obs) & np.isfinite(mod) & np.isfinite(sigma) & (sigma>0)
    r = (obs[m]-mod[m])/sigma[m]
    return float(np.sum(r*r))

def bic(chi2_val: float, k_params: int, n: int) -> float:
    if n <= 0:
        return np.inf
    return float(k_params*np.log(n) + chi2_val)

def lnZ_from_bic(bic_val: float) -> float:
    # Aproximación de Schwarz: ln Z ≈ −0.5 BIC
    return float(-0.5*bic_val)
