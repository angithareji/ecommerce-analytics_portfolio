-- 07_advanced_windows_ctes.sql
-- Purpose: Examples of advanced window functions and CTE patterns for customer spend, cumulative sums,
--          month-over-month growth, moving averages, and percentile segmentation.
-- Tables referenced: orders, order_items, customers, products
-- Notes:
--   - Uses MySQL-specific formatting/date functions (DATE_FORMAT); adapt for other dialects as needed.
--   - Only orders with status in ('paid','shipped','delivered') are treated as revenue-bearing.

-- Rank customers by spend within each state (identify top customers per state)
WITH cr AS (
    SELECT
        o.customer_id,
        c.state,
        SUM(oi.quantity * oi.item_price) AS spend  -- total spend per customer
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
    GROUP BY o.customer_id, c.state
)
SELECT
    state,
    customer_id,
    spend,
    RANK() OVER (PARTITION BY state ORDER BY spend DESC) AS state_rank  -- rank customers within state
FROM cr;

-- Cumulative revenue over time (monthly)
WITH m AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.item_price) AS rev  -- revenue per month
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY 1
)
SELECT
    month,
    rev,
    SUM(rev) OVER (ORDER BY month) AS cumulative_rev  -- running total revenue
FROM m;

-- Month-over-month percent change (MoM %)
WITH m AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.item_price) AS rev
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY 1
)
SELECT
    month,
    rev,
    ROUND(
        (rev - LAG(rev) OVER (ORDER BY month)) / NULLIF(LAG(rev) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_pct  -- percent change vs prior month; NULLIF avoids divide-by-zero
FROM m
ORDER BY month;

-- 3-month moving average of category revenue (rolling window)
WITH mc AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        p.category,
        SUM(oi.quantity * oi.item_price) AS rev
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY 1, 2
)
SELECT
    month,
    category,
    rev,
    ROUND(
        AVG(rev) OVER (
            PARTITION BY category
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS mov_avg_3m  -- centered trailing 3-month moving average per category
FROM mc
ORDER BY month, category;

-- Customer revenue percentiles (NTILE for segmentation)
WITH cr AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.item_price) AS revenue  -- lifetime revenue per customer
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    revenue,
    NTILE(100) OVER (ORDER BY revenue) AS percentile  -- percentile rank (1..100)
FROM cr;
