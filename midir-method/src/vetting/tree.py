from __future__ import annotations

def is_clean_allwise_row(r) -> bool:
    """
    Criterio mínimo de limpieza en AllWISE:
    - w3snr >= 5
    - w4snr >= 5
    - cc_flags[2] == '0'  (W3)
    - cc_flags[3] == '0'  (W4)
    - ext_flg == 0
    """
    try:
        w3snr = float(r.get('w3snr', float('nan')))
        w4snr = float(r.get('w4snr', float('nan')))
        cc = str(r.get('cc_flags', '    '))
        ext = int(r.get('ext_flg', -1))
    except Exception:
        return False
    ok = True
    ok &= (w3snr >= 5.0) and (w4snr >= 5.0)
    ok &= (len(cc) >= 4 and (cc[2] == '0') and (cc[3] == '0'))
    ok &= (ext == 0)
    return bool(ok)
