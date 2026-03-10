# Power BI Dashboard 2 — Customer & Product Deep-Dive (Retention Studio)

## Goal
Show customer quality (RFM), retention/cohort behavior, and product performance to support growth recommendations.

## Data Inputs
- `dw_customer_lifetime` (SQL)
- `dw_customer_rfm` (SQL or Pandas output)
- `dw_product_monthly` (SQL)
Optional:
- `cohort_retention_matrix.csv` (from Pandas)
- `orders` + `order_items` for customer drillthrough

## Required Analytics Areas
1. **VIP Identification** (top decile monetary)
2. **RFM Segmentation** (recency/frequency/monetary + segments)
3. **Cohort Retention** (first order month cohorts, retention % over time)
4. **Product Trends** (monthly revenue, units, ASP)

## Pages & Visuals
### Page 1: RFM Overview
- Scatter: Recency vs Monetary (bubble size = Frequency)
- KPI cards: Avg LTV, VIP customer count, Repeat rate
- Table: Top customers (drillthrough)

### Page 2: Cohort Retention
- Heatmap/Matrix: Cohort Month x Months Since First Order = Retention %
- Line chart: Retention curve for selected cohort(s)

### Page 3: Product Performance
- Small multiples: Revenue trend for top products
- Bar: Top products by revenue (category slicer)

### Drillthrough: Customer Profile
- Customer summary (LTV, orders, last order date, RFM)
- Recent order list

## Interactions & UX
- Sync slicers across pages: Date, Category, Region
- Tooltips: RFM tooltip on hover
- Bookmarks: “Acquisition Focus” vs “Retention Focus”

## Validation / Acceptance Criteria
- RFM numbers match Pandas export for sample customers.
- Cohort matrix values match manual check for 1 cohort.
- Drillthrough filters correctly.
