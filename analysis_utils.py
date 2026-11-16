"""Read the local CSV inputs used by the analysis notebook."""

from pathlib import Path

import pandas as pd

DATA_DIR = Path(__file__).resolve().parent / "data"


def load_data(filename: str) -> pd.DataFrame:
    """Load an input table with consistent floating-point parsing."""
    return pd.read_csv(DATA_DIR / filename, float_precision="round_trip")
