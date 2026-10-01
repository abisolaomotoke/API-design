-- explain.sql
-- Query plans for the two heaviest queries.
-- Our test data is tiny, so Postgres would normally just read the whole table.
-- Turning off sequential scans for this session shows that the indexes CAN be used.

SET enable_seqscan = off;

-- =====================================================================
-- HEAVY QUERY 1: Browse products (Action 2)
-- Expect to see: products_category_audience_idx
-- =====================================================================
EXPLAIN ANALYZE
SELECT
  p.id,
  p.name,
  p.price,
  COALESCE(SUM(c.stock_quantity), 0) AS total_stock,
  jsonb_agg(jsonb_build_object('colour', c.colour, 'inStock', c.stock_quantity > 0) ORDER BY c.colour) AS colours
FROM products p
LEFT JOIN product_colours c
  ON c.product_id = p.id AND c.deleted_at IS NULL
WHERE p.deleted_at IS NULL
  AND p.category = 'bags'
  AND p.target_audience = 'women'
  AND p.price BETWEEN 0 AND 10000000
GROUP BY p.id
ORDER BY p.price ASC, p.id
LIMIT 20 OFFSET 0;

-- =====================================================================
-- HEAVY QUERY 2: Cart snapshot used when placing an order (Action 4)
-- Expect to see: cart_items_cart_colour_unique
-- =====================================================================
EXPLAIN ANALYZE
SELECT ci.product_colour_id,
       ci.quantity,
       pc.colour AS colour_name,
       p.name    AS product_name,
       p.price   AS unit_price,
       p.seller_id
FROM cart_items ci
JOIN product_colours pc ON pc.id = ci.product_colour_id
JOIN products p         ON p.id = pc.product_id
WHERE ci.cart_id = '40000000-0000-0000-0000-000000000001';