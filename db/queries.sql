-- queries.sql
-- The five queries for the five important actions.
-- Run seed.sql first. Run these in order. To run them again, run seed.sql first.

-- =====================================================================
-- ACTION 1: Seller lists a product (with its colours and stock)
-- =====================================================================
BEGIN;

WITH new_product AS (
  INSERT INTO products (seller_id, name, image_url, category, target_audience, price, currency, size_or_dimensions, description, material)
  VALUES ('10000000-0000-0000-0000-000000000001', 'Mini Clutch Bag', 'https://example.com/clutch.jpg',
          'bags', 'women', 3000000, 'NGN', 'Small', 'Small evening clutch.', 'Satin')
  RETURNING id
)
INSERT INTO product_colours (product_id, colour, stock_quantity)
SELECT np.id, c.colour, c.stock
FROM new_product np
CROSS JOIN (VALUES ('Pink', 4), ('Gold', 2)) AS c(colour, stock)
RETURNING product_id, colour, stock_quantity;

COMMIT;

-- =====================================================================
-- ACTION 2: Buyer browses products (filter by category, audience and price; sorted; paginated)
-- =====================================================================
SELECT
  p.id,
  p.name,
  p.image_url,
  p.price,
  p.currency,
  p.size_or_dimensions,
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
-- ACTION 3: Buyer adds a colour to the cart
-- Adds to the quantity if the colour is already in the cart.
-- Only works if the colour exists, is not deleted, and has stock.
-- =====================================================================
INSERT INTO cart_items (cart_id, product_colour_id, quantity)
SELECT '40000000-0000-0000-0000-000000000001'::uuid, pc.id, 1
FROM product_colours pc
WHERE pc.id = '30000000-0000-0000-0000-000000000002'
  AND pc.deleted_at IS NULL
  AND pc.stock_quantity >= 1
ON CONFLICT (cart_id, product_colour_id)
DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity,
              updated_at = now()
RETURNING id, product_colour_id, quantity;

-- =====================================================================
-- ACTION 4: Buyer places an order (everything in ONE transaction)
-- =====================================================================
BEGIN;

-- 1. Take a snapshot of the cart, with the names and prices as they are right now
CREATE TEMP TABLE cart_snapshot ON COMMIT DROP AS
SELECT ci.product_colour_id,
       ci.quantity,
       pc.colour  AS colour_name,
       p.name     AS product_name,
       p.price    AS unit_price,
       p.seller_id
FROM cart_items ci
JOIN product_colours pc ON pc.id = ci.product_colour_id
JOIN products p         ON p.id = pc.product_id
WHERE ci.cart_id = '40000000-0000-0000-0000-000000000001';

-- 2. Reduce stock, only where there is enough (the check constraint is the safety net)
UPDATE product_colours pc
SET stock_quantity = pc.stock_quantity - s.quantity,
    updated_at = now()
FROM cart_snapshot s
WHERE pc.id = s.product_colour_id
  AND pc.stock_quantity >= s.quantity
RETURNING pc.colour, pc.stock_quantity AS stock_left;

-- 3. Create the order with the total worked out from the snapshot
INSERT INTO orders (id, buyer_id, total, currency, status, delivery_address)
SELECT '50000000-0000-0000-0000-000000000003'::uuid,
       '00000000-0000-0000-0000-000000000004'::uuid,
       SUM(unit_price * quantity),
       'NGN',
       'pending',
       '5 Adeola Odeku Street, Victoria Island, Lagos'
FROM cart_snapshot
RETURNING id, total, status;

-- 4. Create the order items, copying name, colour and price
INSERT INTO order_items (order_id, seller_id, product_colour_id, product_name, colour_name, unit_price, quantity, status)
SELECT '50000000-0000-0000-0000-000000000003'::uuid,
       seller_id, product_colour_id, product_name, colour_name, unit_price, quantity, 'pending'
FROM cart_snapshot
RETURNING product_name, colour_name, quantity;

-- 5. Empty the cart
DELETE FROM cart_items
WHERE cart_id = '40000000-0000-0000-0000-000000000001';

COMMIT;

-- =====================================================================
-- ACTION 5: Seller marks their item as shipped, and the order updates if all items shipped
-- =====================================================================
BEGIN;

-- 1. Lock the order so two sellers cannot update at the same moment
SELECT id FROM orders
WHERE id = '50000000-0000-0000-0000-000000000001'
FOR UPDATE;

-- 2. Ship the item (only if it belongs to this seller and is currently "paid")
UPDATE order_items
SET status = 'shipped', updated_at = now()
WHERE id = '51000000-0000-0000-0000-000000000002'
  AND seller_id = '10000000-0000-0000-0000-000000000002'
  AND status = 'paid'
RETURNING id, status;

-- 3. If every item in the order is now shipped or delivered, move the order to shipped
UPDATE orders
SET status = 'shipped', updated_at = now()
WHERE id = '50000000-0000-0000-0000-000000000001'
  AND status = 'paid'
  AND NOT EXISTS (
    SELECT 1 FROM order_items
    WHERE order_id = '50000000-0000-0000-0000-000000000001'
      AND status NOT IN ('shipped', 'delivered')
  )
RETURNING id, status;

COMMIT;