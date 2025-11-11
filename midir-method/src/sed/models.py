from __future__ import annotations
import numpy as np

# Constantes físicas (SI)
h = 6.62607015e-34  # J s
kB = 1.380649e-23   # J/K
c = 2.99792458e8    # m/s

# Zero points WISE (Jy)
WISE_ZP_JY = {
    "W1": 309.540,
    "W2": 171.787,
    "W3": 31.674,
    "W4": 8.363,
}

# Frecuencias efectivas aproximadas (Hz) para W1..W4 (lambda ~ 3.4, 4.6, 12, 22 um)
WISE_BANDS_HZ = {
    "W1": c / (3.4e-6),
    "W2": c / (4.6e-6),
    "W3": c / (12e-6),
    "W4": c / (22e-6),
}

def hz_from_band(band: str) -> float:
    return float(WISE_BANDS_HZ[band])

def blackbody_nu(nu: np.ndarray, T: float) -> np.ndarray:
    """
    Ley de Planck en frecuencia: B_nu [W m^-2 Hz^-1 sr^-1]
    Se devuelve sin factor de 2*sr/geom detallada ya que el ajuste escala con S.
    """
    nu = np.asarray(nu, dtype=float)
    x = h*nu/(kB*T)
    with np.errstate(over='ignore', invalid='ignore', divide='ignore'):
        B = (2.0*h*(nu**3)/(c**2)) / (np.expm1(x))
    return np.nan_to_num(B)

class M2Dyson:
    """
    Modelo mínimo: fotosfera + BB liso (beta=0).
    Parámetros (theta): [S_star, S_d, T_star, T_w]
    predict(bands_hz, theta) -> flujos modelo (unidades relativas).
    """
    def __init__(self):
        pass

    def predict(self, bands_hz: np.ndarray, theta):
        S_star, S_d, T_star, T_w = theta
        Bstar = blackbody_nu(bands_hz, T_star)
        Bdust = blackbody_nu(bands_hz, T_w)
        return S_star*Bstar + S_d*Bdust

def fit_star_excess_linear(fobs, sigma, Bstar, Bdust):
    """
    Ajuste lineal de S_star y S_d dados Bstar y Bdust (Tw fijo):
    Resuelve (X^T W X) theta = X^T W y, con X=[Bstar, Bdust].
    """
    y = np.asarray(fobs, float)
    s = np.asarray(sigma, float)
    m = np.isfinite(y) & np.isfinite(s) & (s>0)
    X = np.vstack([Bstar, Bdust]).T
    X = X[m]
    y = y[m]
    w = 1.0/(s[m]**2)
    # Ponderado
    Xw = X * w[:, None]
    A = X.T @ Xw
    b = X.T @ (w*y)
    # Resolver 2x2 estable
    try:
        theta = np.linalg.solve(A, b)
    except np.linalg.LinAlgError:
        theta = np.array([np.nan, np.nan])
    return float(theta[0]), float(theta[1])
