-- 01_create_order_revenue.sql
-- Purpose: Create an order-level revenue table (one row per order_id)
-- Business context: Normalize item-level revenue into an "order total" so KPIs like AOV become simple & fast.

CREATE TABLE IF NOT EXISTS order_revenue AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_date,
  DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
  o.order_status,
  SUM(oi.quantity * oi.item_price) AS order_revenue,
  SUM(oi.quantity) AS order_items
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  o.order_id, o.customer_id, o.order_date, order_month, o.order_status;
