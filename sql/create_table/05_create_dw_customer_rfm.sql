-- 05_create_dw_customer_rfm.sql
-- Purpose: RFM features as-of a snapshot date
-- Business context: RFM is a standard retention model: Recency (days since last purchase),
-- Frequency (# orders), Monetary (total spend).
-- Change SNAPSHOT_DATE to any date you want to score "as of".

-- Set the snapshot date (edit this literal as needed)
-- Example: '2024-12-31'
SET @SNAPSHOT_DATE = '2024-12-31';

CREATE TABLE IF NOT EXISTS dw_customer_rfm AS
SELECT
  o.customer_id,
  DATEDIFF(@SNAPSHOT_DATE, MAX(o.order_date)) AS recency_days,
  COUNT(DISTINCT o.order_id) AS frequency_orders,
  ROUND(SUM(oi.quantity * oi.item_price), 2) AS monetary_spend
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
  AND o.order_date <= @SNAPSHOT_DATE
GROUP BY o.customer_id;
