-- 05_marketing_attribution.sql
-- Purpose: Marketing attribution — spend, ROAS, CPA and channel ranking.
-- Tables referenced: marketing_spend, orders, order_items
-- Notes:
--   - Uses MySQL DATE() / DATE_FORMAT; adapt for other SQL dialects.
--   - Join logic is conservative (LEFT JOIN) to avoid dropping spend rows with no matching revenue/orders.

-- Monthly marketing spend by channel (YYYY-MM)
SELECT
    DATE_FORMAT(spend_date, '%Y-%m') AS month,  -- bucket spend by month
    channel,
    SUM(spend) AS total_spend                   -- total spend per channel/month
FROM marketing_spend
GROUP BY 1, 2
ORDER BY month, channel;

-- Daily revenue derived from delivered/paid/shipped orders (used to compute ROAS)
WITH daily_rev AS (
    SELECT
        DATE(o.order_date) AS day,                       -- day-level revenue
        SUM(oi.quantity * oi.item_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
    GROUP BY 1
)
-- Per-spend-row ROAS: revenue / spend (NULL if spend = 0)
SELECT
    m.spend_date,
    m.channel,
    m.spend,
    COALESCE(d.revenue, 0) AS revenue,  -- 0 when no matching revenue that day
    CASE
        WHEN m.spend = 0 THEN NULL
        ELSE ROUND(COALESCE(d.revenue, 0) / m.spend, 2)  -- round ROAS for reporting
    END AS roas
FROM marketing_spend m
LEFT JOIN daily_rev d ON d.day = m.spend_date
ORDER BY m.spend_date, m.channel;

-- Aggregate ROAS / ranking by channel across all dates
WITH agg AS (
    SELECT
        channel,
        SUM(spend) AS total_spend,
        SUM(COALESCE(d.revenue, 0)) AS total_revenue
    FROM marketing_spend m
    LEFT JOIN (
        SELECT
            DATE(o.order_date) AS day,
            SUM(oi.quantity * oi.item_price) AS revenue
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        WHERE o.order_status IN ('paid', 'shipped', 'delivered')
        GROUP BY 1
    ) d ON d.day = m.spend_date
    GROUP BY channel
)
SELECT
    channel,
    total_spend,
    total_revenue,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,     -- rank channels by spend
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank  -- rank channels by revenue
FROM agg;

-- CPA (cost per acquisition) estimation using delivered orders as conversions
WITH daily_orders AS (
    SELECT
        DATE(order_date) AS day,
        COUNT(*) AS conv                         -- conversions per day (delivered orders)
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY 1
),
joined AS (
    SELECT
        m.channel,
        m.spend_date AS day,
        m.spend,
        COALESCE(d.conv, 0) AS conv              -- 0 when no conversions that day
    FROM marketing_spend m
    LEFT JOIN daily_orders d ON d.day = m.spend_date
)
SELECT
    channel,
    ROUND(SUM(spend) / NULLIF(SUM(conv), 0), 2) AS cpa  -- NULLIF avoids div-by-zero; rounded for reporting
FROM joined
GROUP BY channel;
