CREATE OR REPLACE VIEW ${AppSchema}.v_order_summary AS
SELECT
    o.id            AS order_id,
    o.order_number,
    o.status,
    o.ordered_at,
    c.code          AS customer_code,
    c.full_name     AS customer_name,
    COUNT(oi.id)    AS item_count,
    COALESCE(SUM(oi.line_total), 0) AS total_amount,
    o.currency
FROM ${AppSchema}.orders o
JOIN ${AppSchema}.customers c      ON c.id = o.customer_id
LEFT JOIN ${AppSchema}.order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.order_number, o.status, o.ordered_at, c.code, c.full_name, o.currency;
