from __future__ import annotations
import os
from pathlib import Path
from typing import Union, Iterable, Optional
import pandas as pd

PathLike = Union[str, os.PathLike]

def load_table(path: PathLike) -> pd.DataFrame:
    """
    Carga tabla Parquet o CSV (.csv o .csv.gz) y devuelve DataFrame.
    - Parquet: pyarrow/fastparquet
    - CSV: pandas.read_csv (UTF-8)
    """
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"No existe: {p}")
    suf = "".join(p.suffixes).lower()
    if suf.endswith(".parquet"):
        return pd.read_parquet(p)
    if suf.endswith(".csv") or suf.endswith(".csv.gz"):
        return pd.read_csv(p)
    raise ValueError(f"Formato no soportado: {p}")

def save_table(df: pd.DataFrame, path: PathLike) -> None:
    """
    Guarda DataFrame en Parquet (snappy) o CSV según extensión.
    """
    p = Path(path)
    suf = "".join(p.suffixes).lower()
    if suf.endswith(".parquet"):
        df.to_parquet(p, index=False)
    elif suf.endswith(".csv") or suf.endswith(".csv.gz"):
        df.to_csv(p, index=False)
    else:
        raise ValueError(f"Extensión no soportada para guardar: {p}")

def left_join_on(a: pd.DataFrame, b: pd.DataFrame, on: Union[str, Iterable[str]]) -> pd.DataFrame:
    """Left join estándar."""
    return a.merge(b, how="left", on=on)
