-- 06_operations_efficiency.sql
-- Purpose: Delivery, refund/cancellation, basket and fulfillment metrics to monitor operations efficiency.
-- Tables referenced: orders, order_items, customers
-- Notes:
--   - Uses MySQL DATEDIFF/ROUND/NULLIF functions; adapt for other SQL dialects if needed.
--   - Delivery-time metrics require delivered_date to be present.

-- Average days from order -> delivery (all delivered orders)
SELECT
    ROUND(AVG(DATEDIFF(delivered_date, order_date)), 2) AS avg_days  -- mean delivery time (days), rounded
FROM orders
WHERE order_status = 'delivered'  -- only completed deliveries
  AND delivered_date IS NOT NULL;  -- ensure delivered_date exists

-- Average delivery time by customer state (top 5 slowest states)
SELECT
    c.state,
    ROUND(AVG(DATEDIFF(o.delivered_date, o.order_date)), 2) AS avg_days  -- avg delivery days per state
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.delivered_date IS NOT NULL
GROUP BY c.state
ORDER BY avg_days DESC
LIMIT 5;  -- focus on worst-performing states for ops follow-up

-- Percentage of bad orders (cancelled or refunded)
SELECT
    ROUND(100.0 * SUM(order_status IN ('cancelled', 'refunded')) / COUNT(*), 2) AS bad_order_pct
FROM orders;  -- higher value indicates fulfillment/quality issues

-- Average items per order (basket size)
WITH ot AS (
    SELECT
        o.order_id,
        SUM(oi.quantity) AS items  -- total items per order
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id
)
SELECT
    ROUND(AVG(items), 2) AS avg_items_per_order  -- mean basket size, rounded
FROM ot;

-- Fulfillment rate: delivered orders as % of orders that progressed to placed/paid/shipped/delivered
SELECT
    ROUND(
        SUM(order_status = 'delivered')
        / NULLIF(SUM(order_status IN ('placed', 'paid', 'shipped', 'delivered')), 0) * 100,
        2
    ) AS fulfillment_rate_pct  -- NULLIF avoids division by zero
FROM orders;