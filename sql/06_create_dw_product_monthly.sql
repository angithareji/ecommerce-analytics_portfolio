-- 06_create_dw_product_monthly.sql
-- Purpose: Product-month performance table (revenue & units)
-- Business context: Used for product leaderboards, category trends, and "hero product" stories.

CREATE TABLE IF NOT EXISTS dw_product_monthly AS
SELECT
  p.product_id,
  p.product_name,
  p.category,
  DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
  STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'),'-01'), '%Y-%m-%d') AS month_start_date,
  ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.quantity * oi.item_price) / NULLIF(SUM(oi.quantity),0), 2) AS avg_selling_price
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY p.product_id, p.product_name, p.category, order_month, month_start_date;
