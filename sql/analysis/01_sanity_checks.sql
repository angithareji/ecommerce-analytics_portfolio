-- 01_sanity_checks.sql
-- Purpose: Basic sanity checks and dataset overview for the ecommerce analytics project.
-- Tables referenced: customers, orders
-- Notes: DATE_FORMAT is MySQL-specific; adjust for other SQL dialects if needed.

-- Row counts for primary tables (quick integrity check)
SELECT
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM orders) AS orders;

-- Order status distribution: percent delivered vs. cancelled/refunded
SELECT
    ROUND(100.0 * SUM(order_status = 'delivered') / COUNT(*), 2) AS delivered_pct,
    ROUND(100.0 * SUM(order_status IN ('cancelled', 'refunded')) / COUNT(*), 2) AS refund_cancel_pct
FROM orders;

-- Monthly orders time series (YYYY-MM) to check seasonality / data continuity
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 1;

-- Top 5 customer cities by count (helps surface geographic data issues)
SELECT
    city,
    COUNT(*) AS customers
FROM customers
GROUP BY city
ORDER BY customers DESC, city
LIMIT 5;

-- Average number of orders per customer (rounded)
SELECT
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer
FROM (
    -- per-customer order counts
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) t;