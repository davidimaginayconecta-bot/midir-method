from __future__ import annotations

def _clamp01(x: float) -> float:
    return 0.0 if x < 0 else 1.0 if x > 1 else float(x)

def iwi(scores: dict) -> float:
    """
    IWI = sum_j w_j * S_j, con pesos nominales:
    S_suav, S_beta0, S_var, S_morf, S_ener, S_ctxt
    Pesos (0.30, 0.25, 0.15, 0.10, 0.10, 0.10) renormalizados a 1.0
    """
    weights = {
        'S_suav': 0.30,
        'S_beta0': 0.25,
        'S_var': 0.15,
        'S_morf': 0.10,
        'S_ener': 0.10,
        'S_ctxt': 0.10,
    }
    # Normalizar pesos a suma 1 por robustez
    s = sum(weights.values())
    weights = {k: v/s for k, v in weights.items()}
    total = 0.0
    for k,w in weights.items():
        v = _clamp01(scores.get(k, 0.0))
        total += w * v
    # Clamp final por seguridad numérica
    return _clamp01(total)
