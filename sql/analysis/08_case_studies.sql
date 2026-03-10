-- 08_case_studies.sql
-- Purpose: Business case-study style analyses — monthly topline, category YoY, and customer segmentation.
-- Tables referenced: orders, order_items, products, customers
-- Notes:
--   - Uses MySQL DATE_FORMAT/YEAR functions; adapt for other SQL dialects.
--   - Only orders with status in ('paid','shipped','delivered') are treated as revenue-bearing.

-- Monthly orders and revenue (YYYY-MM)
WITH m AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,          -- month bucket for time series
        COUNT(DISTINCT o.order_id) AS orders,                -- unique orders in month
        SUM(oi.quantity * oi.item_price) AS revenue          -- monthly revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
    GROUP BY 1
)
SELECT *
FROM m
ORDER BY month;  -- chronological output

-- Category year-over-year growth (2023 vs 2024)
WITH cy AS (
    SELECT
        p.category,
        YEAR(o.order_date) AS yr,
        SUM(oi.quantity * oi.item_price) AS rev               -- revenue by category/year
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
      AND YEAR(o.order_date) IN (2023, 2024)                 -- focus years for YoY comparison
    GROUP BY p.category, YEAR(o.order_date)
),
pivoted AS (
    SELECT
        category,
        MAX(CASE WHEN yr = 2023 THEN rev END) AS r23,        -- pivot 2023
        MAX(CASE WHEN yr = 2024 THEN rev END) AS r24         -- pivot 2024
    FROM cy
    GROUP BY category
)
SELECT
    category,
    r23,
    r24,
    ROUND((r24 - r23) / NULLIF(r23, 0) * 100, 2) AS yoy_growth_pct  -- YoY % (NULLIF avoids div-by-zero)
FROM pivoted
ORDER BY yoy_growth_pct DESC;  -- highest growth first

-- Customer spend segmentation and revenue share by segment
WITH cr AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.item_price) AS spend             -- lifetime spend per customer
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.customer_id
),
seg AS (
    SELECT
        customer_id,
        spend,
        CASE                                                  -- simple RFM-like tiers
            WHEN spend < 200 THEN 'Bronze'
            WHEN spend < 500 THEN 'Silver'
            ELSE 'Gold'
        END AS segment
    FROM cr
)
SELECT
    segment,
    COUNT(*) AS customers,                                  -- number of customers per segment
    ROUND(SUM(spend), 2) AS revenue,                        -- total revenue per segment
    ROUND(100.0 * SUM(spend) / SUM(SUM(spend)) OVER (), 2) AS revenue_share_pct  -- segment share of total
FROM seg
GROUP BY segment
ORDER BY revenue DESC;  -- largest revenue segments first