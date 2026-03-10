-- 03_customer_retention.sql
-- Purpose: Customer analytics — signup trends, repeat behavior, cohort retention, and spend growth.
-- Tables referenced: customers, orders, order_items
-- Notes:
--   - Uses MySQL date functions (DATE_FORMAT, TIMESTAMPDIFF, YEAR); adapt for other SQL dialects.
--   - Only orders with status in ('paid','shipped','delivered') are treated as revenue-bearing / valid events.

-- New customers by signup month (YYYY-MM)
SELECT
    DATE_FORMAT(signup_date, '%Y-%m') AS month,  -- bucket signups by month
    COUNT(*) AS new_customers
FROM customers
GROUP BY 1
ORDER BY 1;

-- Repeat buyer percentage (share of customers with 2+ qualifying orders)
WITH co AS (
    SELECT customer_id, COUNT(*) AS cnt
    FROM orders
    WHERE order_status IN ('paid', 'shipped', 'delivered')  -- only count completed/paid orders
    GROUP BY customer_id
)
SELECT
    ROUND(100.0 * SUM(cnt >= 2) / COUNT(*), 2) AS repeat_buyer_pct  -- percent with >=2 orders
FROM co;

-- Top 10 customers by lifetime spend (rounded)
SELECT
    o.customer_id,
    ROUND(SUM(oi.quantity * oi.item_price), 2) AS total_spent
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
GROUP BY o.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Cohort analysis: active customers by month for first 0-3 months after first qualifying order
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS cohort_date
    FROM orders
    WHERE order_status IN ('paid', 'shipped', 'delivered')  -- cohort defined on first qualifying order
    GROUP BY customer_id
),
activity AS (
    SELECT
        f.customer_id,
        DATE_FORMAT(f.cohort_date, '%Y-%m') AS cohort,               -- cohort bucket (YYYY-MM)
        TIMESTAMPDIFF(MONTH, f.cohort_date, o.order_date) AS month_num  -- months since cohort
    FROM first_order f
    JOIN orders o ON o.customer_id = f.customer_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
)
SELECT
    cohort,
    month_num,
    COUNT(DISTINCT customer_id) AS active_customers  -- distinct active users in cohort/month
FROM activity
WHERE month_num BETWEEN 0 AND 3  -- focus on first 4 months
GROUP BY cohort, month_num
ORDER BY cohort, month_num;

-- Year-over-year revenue per customer and customers with >30% growth (2023 -> 2024)
WITH yr AS (
    SELECT
        o.customer_id,
        YEAR(o.order_date) AS yr,
        SUM(oi.quantity * oi.item_price) AS rev
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.customer_id, YEAR(o.order_date)
),
y AS (
    SELECT
        customer_id,
        MAX(CASE WHEN yr = 2023 THEN rev END) AS r23,  -- revenue in 2023
        MAX(CASE WHEN yr = 2024 THEN rev END) AS r24   -- revenue in 2024
    FROM yr
    GROUP BY customer_id
)
SELECT
    customer_id,
    r23,
    r24,
    ROUND((r24 - r23) / NULLIF(r23, 0) * 100, 2) AS growth_pct  -- pct growth; NULLIF avoids div-by-zero
FROM y
WHERE r24 IS NOT NULL
  AND r23 IS NOT NULL
  AND (r24 - r23) > 0.3 * r23;  -- filter to customers with >30% absolute growth