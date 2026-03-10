from pathlib import Path
import pandas as pd

def load_raw_data(base_path: str = "../data/raw") -> dict:
    base = Path(base_path)
    return {
        "orders": pd.read_csv(base / "orders.csv"),
        "customers": pd.read_csv(base / "customers.csv"),
        "order_items": pd.read_csv(base / "order_items.csv"),
        "products": pd.read_csv(base / "products.csv"),
        "marketing_spend": pd.read_csv(base / "marketing_spend.csv"),
    }
