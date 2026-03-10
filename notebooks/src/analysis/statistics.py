import pandas as pd

def revenue_summary(df: pd.DataFrame, revenue_col: str = "revenue") -> pd.Series:
    return df[revenue_col].describe()

def customer_spend_summary(df: pd.DataFrame) -> pd.DataFrame:
    grouped = df.groupby("customer_id")["revenue"].sum().reset_index(name="total_spend")
    grouped["spend_quartile"] = pd.qcut(grouped["total_spend"], 4, labels=["Q1", "Q2", "Q3", "Q4"])
    return grouped

def product_revenue_stats(df: pd.DataFrame) -> pd.DataFrame:
    return df.groupby("product_id")["revenue"].agg(
        mean_revenue="mean",
        median_revenue="median",
        std_revenue="std",
        min_revenue="min",
        max_revenue="max"
    ).reset_index()
