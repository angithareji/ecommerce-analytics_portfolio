-- 02_revenue_kpis.sql
-- Purpose: Core revenue KPI queries for executive dashboarding.
-- Assumptions:
--   - order_status values indicate lifecycle; we only count revenue from paid/shipped/delivered orders.
--   - DATE_FORMAT, QUARTER, YEAR functions are MySQL-specific; adapt for other dialects if needed.
--   - Prices stored on order_items (item_price) are final charged amounts; taxes/discounts already applied if needed.

-- Total revenue across all qualifying orders
SELECT
    -- sum of quantity * item price, rounded to 2 decimals for reporting
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered');

-- Monthly revenue time series and order counts (YYYY-MM)
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,        -- period bucket
    COUNT(DISTINCT o.order_id) AS orders,               -- unique orders in month
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue -- monthly revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')
GROUP BY 1
ORDER BY 1;

-- Average Order Value (AOV) computed from monthly aggregates
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.quantity * oi.item_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY 1
)
SELECT
    month,
    -- AOV = total revenue / number of orders, rounded for display
    ROUND(revenue / orders, 2) AS aov
FROM monthly
ORDER BY month;

-- Top revenue quarter in 2024 (shows seasonality / largest revenue quarter)
SELECT
    CONCAT('Q', QUARTER(o.order_date)) AS qtr,
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')
  AND YEAR(o.order_date) = 2024
GROUP BY qtr
ORDER BY revenue DESC
LIMIT 1;

-- Share of revenue from Electronics category (percentage of total revenue)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN p.category = 'Electronics' THEN oi.quantity * oi.item_price END)
        / NULLIF(SUM(oi.quantity * oi.item_price), 0),
        2
    ) AS electronics_share_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered');