-- 10_interview_showcase_queries.sql
-- Purpose: Short, interview-friendly showcase queries (customer deciles, product deltas, top products).
-- Tables referenced: orders, order_items
-- Notes:
--   - Uses MySQL DATE_FORMAT/NTILE/LAG window functions; adapt for other SQL dialects.
--   - Only orders with status in ('paid','shipped','delivered') are counted as revenue-bearing.

-- Top 10% customers by lifetime spend (decile = 1 => highest spenders)
WITH cr AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.item_price) AS spend  -- lifetime spend per customer
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
    GROUP BY o.customer_id
),
ranked AS (
    SELECT
        customer_id,
        spend,
        NTILE(10) OVER (ORDER BY spend DESC) AS decile  -- split into 10 deciles by spend
    FROM cr
)
SELECT *
FROM ranked
WHERE decile = 1;  -- highest 10% of customers by spend

-- Largest month-over-month revenue increases by product (shows recent product momentum)
WITH mp AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,  -- month bucket (YYYY-MM)
        oi.product_id,
        SUM(oi.quantity * oi.item_price) AS rev      -- revenue per product/month
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY 1, 2
),
d AS (
    SELECT
        product_id,
        month,
        rev,
        rev - LAG(rev) OVER (PARTITION BY product_id ORDER BY month) AS delta  -- change vs prior month
    FROM mp
)
SELECT
    month,
    product_id,
    delta
FROM d
ORDER BY delta DESC
LIMIT 10;  -- top 10 single-month increases

-- Top 10 products by total revenue (all-time)
WITH prod_rev AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity * oi.item_price) AS revenue  -- total revenue per product
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY oi.product_id
)
SELECT *
FROM prod_rev
ORDER BY revenue DESC
LIMIT 10;  -- top 10 revenue-generating products