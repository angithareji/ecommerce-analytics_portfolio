-- 09_create_views.sql
-- Purpose: Reusable views for dashboards and downstream reporting.
-- Notes:
--   - Uses MySQL DATE_FORMAT / CURDATE; adapt functions for other SQL dialects.
--   - Views restrict to revenue-bearing orders (paid/shipped/delivered).

-- Customer RFM view: recency (days since last order), frequency (order count), monetary (total spend)
CREATE OR REPLACE VIEW vw_customer_rfm AS
SELECT
    o.customer_id,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS recency_days,  -- days since last qualifying order
    COUNT(*) AS frequency_orders,                            -- number of qualifying orders
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS monetary_spend  -- lifetime monetary spend, rounded
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')    -- only revenue-bearing orders
GROUP BY o.customer_id;

-- Monthly KPIs view: orders, revenue and AOV (YYYY-MM)
CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,             -- month bucket (YYYY-MM)
    COUNT(DISTINCT o.order_id) AS orders,                    -- unique orders in month
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue,   -- monthly revenue, rounded
    ROUND(SUM(oi.quantity * oi.item_price) / COUNT(DISTINCT o.order_id), 2) AS aov  -- average order value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')    -- revenue-bearing orders only
GROUP BY 1;

-- Category performance view: product counts, units sold and revenue by category
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    p.category,
    COUNT(DISTINCT oi.product_id) AS products,               -- distinct products in category
    SUM(oi.quantity) AS units_sold,                          -- total units sold in category
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue    -- category revenue, rounded
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')    -- revenue-bearing orders only
GROUP BY p.category;
