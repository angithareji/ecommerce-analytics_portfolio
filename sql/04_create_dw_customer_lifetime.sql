-- 04_create_dw_customer_lifetime.sql
-- Purpose: Customer lifetime summary (LTV proxy).
-- Business context: Used for VIP lists, customer segmentation, and executive retention stories.

CREATE TABLE IF NOT EXISTS dw_customer_lifetime AS
SELECT
  o.customer_id,
  MIN(o.order_date) AS first_order_date,
  MAX(o.order_date) AS last_order_date,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(SUM(oi.quantity * oi.item_price), 2) AS lifetime_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY o.customer_id;
