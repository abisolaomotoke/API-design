-- invalid_inserts.sql
-- Three invalid states. Each one should be REJECTED by the database with an ERROR.
-- Run seed.sql first so the data these tests refer to exists.

-- =====================================================================
-- TEST 1: A buyer cannot have two carts
-- Chidi (buyer 4) already has a cart from the seed data.
-- Expected: ERROR ... violates unique constraint "carts_user_id_unique"
-- =====================================================================
INSERT INTO carts (user_id)
VALUES ('00000000-0000-0000-0000-000000000004');

-- =====================================================================
-- TEST 2: A product cannot have a price of zero or less
-- Expected: ERROR ... violates check constraint "products_price_positive"
-- =====================================================================
INSERT INTO products (seller_id, name, image_url, category, target_audience, price, currency, size_or_dimensions, description)
VALUES ('10000000-0000-0000-0000-000000000001', 'Free Bag', 'https://example.com/free.jpg',
        'bags', 'women', 0, 'NGN', 'Small', 'This should not be allowed.');

-- =====================================================================
-- TEST 3: A colour that appears in an order cannot be deleted
-- The Red crossbody bag (colour 4) is in Chidi's delivered order.
-- Expected: ERROR ... violates foreign key constraint "order_items_product_colour_id_fkey"
-- =====================================================================
DELETE FROM product_colours
WHERE id = '30000000-0000-0000-0000-000000000004';