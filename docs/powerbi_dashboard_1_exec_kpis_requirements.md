# Power BI Dashboard 1 — Executive KPI & Trends (C‑Suite Snapshot)

## Goal
Give leadership a fast, reliable overview of revenue performance and order health over time, with simple filters and drillthrough.

## Data Inputs (preferred)
- `dw_monthly_order_metrics` (from SQL)
- `dim_date` (Power BI date table)
Optional for deeper drill:
- `orders` + `order_items` (row-level)
- `customers` (geo slicing)
- `products` (category slicing)
- `marketing_spend` (if you want channel metrics later)

## Required KPI Definitions
1. **Total Revenue (Recognized)** = sum of revenue for statuses `paid/shipped/delivered`
2. **Orders (Recognized)** = distinct orders for statuses `paid/shipped/delivered`
3. **AOV** = Total Revenue / Orders
4. **Refunded Revenue** = sum revenue where status = `refunded`
5. **Bad Order Rate** = (cancelled + refunded orders) / total orders
6. **MoM % Revenue** and **YoY % Revenue** (time intelligence)

## Pages & Visuals
### Page 1: Overview
- KPI cards: Total Revenue, Orders, AOV, Refund %, Bad Order Rate
- Line chart: Revenue by Month (tooltip: MoM and YoY)
- Column chart: Orders by Month (or combined dual-axis)
- Bar chart: Top Categories by Revenue (if category available)
- Slicers: Date range, Category, Region/State (if available)

### Page 2: Drillthrough (Order Details)
- Table: order_id, customer_id, order_date, status, order_revenue, items
- Filters inherited from Overview (month, category, region)

## Interactions & UX
- Cross-filtering enabled across visuals
- Bookmarks:
  - “Last 3 Months”
  - “YTD”
  - “Presentation Mode”
- Custom tooltip page: Month KPI mini-summary

## Validation / Acceptance Criteria
- Revenue and orders match SQL results for at least 3 chosen months.
- MoM and YoY measures return expected values (spot-check).
- Filters affect all visuals consistently.
