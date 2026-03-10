-- 03_create_dw_customer_monthly.sql
-- Purpose: Customer-month grain table used to compute repeat customer metrics.
-- Business context: Repeat% and retention metrics are easiest when you have customer-by-month activity.

CREATE TABLE IF NOT EXISTS dw_customer_monthly AS
SELECT
  DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
  STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'),'-01'), '%Y-%m-%d') AS month_start_date,
  o.customer_id,
  COUNT(DISTINCT o.order_id) AS orders_in_month,
  ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue_in_month
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY order_month, month_start_date, o.customer_id;
