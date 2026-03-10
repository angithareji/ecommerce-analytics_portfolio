-- 04_product_performance.sql
-- Purpose: Product, category, mix and basket analysis.
-- Tables referenced: products, order_items, orders
-- Notes:
--   - Uses MySQL functions (DATE_FORMAT, LEAST, GREATEST); adapt as needed for other dialects.
--   - Only orders with status in ('paid','shipped','delivered') are treated as revenue-bearing.

-- Top-selling products by units sold (all-time)
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold  -- total units sold per product
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')  -- revenue-bearing orders only
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;

-- Highest revenue product per category (identify category-level winners)
WITH prod_cat AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.item_price) AS revenue  -- revenue per product
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT *
FROM (
    SELECT
        pc.*,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn  -- rank within category
    FROM prod_cat pc
) t
WHERE rn = 1;  -- keep top product per category

-- Monthly category revenue time series (YYYY-MM, category granularity)
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,           -- period bucket
    p.category,
    SUM(oi.quantity * oi.item_price) AS revenue            -- revenue for category in period
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('paid', 'shipped', 'delivered')
GROUP BY 1, 2
ORDER BY month, revenue DESC;

-- Product pairings: most frequently purchased-together product pairs (basket analysis)
SELECT
    LEAST(oi1.product_id, oi2.product_id) AS product_a,     -- canonical pair ordering
    GREATEST(oi1.product_id, oi2.product_id) AS product_b,
    COUNT(*) AS together_orders                             -- number of orders containing the pair
FROM order_items oi1
JOIN order_items oi2
  ON oi1.order_id = oi2.order_id
 AND oi1.product_id < oi2.product_id                      -- avoid self-joins / double counting
GROUP BY 1, 2
ORDER BY together_orders DESC
LIMIT 20;  -- top 20 most common pairs

-- Product contribution to category revenue (pct share within category)
WITH cat_rev AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.item_price) AS rev               -- product revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status IN ('paid', 'shipped', 'delivered')
    GROUP BY p.category, p.product_id, p.product_name
),
cat_tot AS (
    SELECT category, SUM(rev) AS cat_rev                     -- total revenue by category
    FROM cat_rev
    GROUP BY category
)
SELECT
    cr.category,
    cr.product_id,
    cr.product_name,
    ROUND(100.0 * cr.rev / NULLIF(ct.cat_rev, 0), 2) AS pct_of_category  -- pct share; avoid div-by-zero
FROM cat_rev cr
JOIN cat_tot ct USING(category)
ORDER BY category, pct_of_category DESC;