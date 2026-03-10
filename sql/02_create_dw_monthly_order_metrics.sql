-- 02_create_dw_monthly_order_metrics.sql
-- Purpose: Create monthly executive KPIs for Power BI (fast import table)
-- Recognized revenue statuses: paid, shipped, delivered

CREATE TABLE IF NOT EXISTS dw_monthly_order_metrics AS
SELECT
  orv.order_month,
  STR_TO_DATE(CONCAT(orv.order_month,'-01'), '%Y-%m-%d') AS month_start_date,
  YEAR(STR_TO_DATE(CONCAT(orv.order_month,'-01'), '%Y-%m-%d')) AS year_num,
  QUARTER(STR_TO_DATE(CONCAT(orv.order_month,'-01'), '%Y-%m-%d')) AS quarter_num,

  COUNT(DISTINCT CASE WHEN orv.order_status IN ('paid','shipped','delivered') THEN orv.order_id END) AS orders_recognized,
  ROUND(SUM(CASE WHEN orv.order_status IN ('paid','shipped','delivered') THEN orv.order_revenue END), 2) AS revenue_recognized,

  COUNT(DISTINCT CASE WHEN orv.order_status='delivered' THEN orv.order_id END) AS orders_delivered,
  COUNT(DISTINCT CASE WHEN orv.order_status IN ('cancelled','refunded') THEN orv.order_id END) AS orders_bad,

  ROUND(SUM(CASE WHEN orv.order_status='refunded' THEN orv.order_revenue END), 2) AS revenue_refunded,
  ROUND(SUM(CASE WHEN orv.order_status='cancelled' THEN orv.order_revenue END), 2) AS revenue_cancelled,

  SUM(orv.order_items) AS items_sold
FROM order_revenue orv
GROUP BY orv.order_month, month_start_date, year_num, quarter_num;
