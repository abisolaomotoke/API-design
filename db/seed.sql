-- seed.sql
-- Small dataset for local testing. Safe to run more than once (it clears the tables first).
-- The IDs are fixed and readable only so the test queries are easy to write.
-- Real IDs in the app are generated randomly.

BEGIN;

TRUNCATE users CASCADE;

-- ---------- Users (2 sellers, 2 buyers) ----------
INSERT INTO users (id, name, email, phone, password_hash, role) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Ada Okafor',   'ada@example.com',   '08011111111', 'fake-hash-1', 'seller'),
  ('00000000-0000-0000-0000-000000000002', 'Tunde Bello',  'tunde@example.com', '08022222222', 'fake-hash-2', 'seller'),
  ('00000000-0000-0000-0000-000000000003', 'Bisi Adeyemi', 'bisi@example.com',  '08033333333', 'fake-hash-3', 'buyer'),
  ('00000000-0000-0000-0000-000000000004', 'Chidi Eze',    'chidi@example.com', '08044444444', 'fake-hash-4', 'buyer');

-- ---------- Sellers ----------
INSERT INTO sellers (id, user_id, store_name, details) VALUES
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Ada Bags',     'Handmade leather bags from Lagos'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Tunde Kicks',  'Shoes and clothes for everyday wear');

-- ---------- Products (prices in kobo) ----------
INSERT INTO products (id, seller_id, name, image_url, category, target_audience, price, currency, size_or_dimensions, description, material) VALUES
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Large Tote Bag',       'https://example.com/tote.jpg',      'bags',    'women',  8500000,  'NGN', 'Large',  'Large everyday tote bag.',      'Leather'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Small Crossbody Bag',  'https://example.com/crossbody.jpg', 'bags',    'women',  4500000,  'NGN', 'Small',  'Small bag for daily essentials.', 'Leather'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 'Classic Sneakers',     'https://example.com/sneakers.jpg',  'shoes',   'unisex', 12000000, 'NGN', 'EU 42', 'Clean everyday sneakers.',       'Canvas'),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', 'Ankara Shirt',        'https://example.com/shirt.jpg',     'clothes', 'men',    6000000,  'NGN', 'Medium', 'Short-sleeve Ankara print shirt.', 'Cotton');

-- ---------- Product colours (stock per colour) ----------
INSERT INTO product_colours (id, product_id, colour, stock_quantity) VALUES
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Black',  0),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'Blue',   5),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001', 'Green',  3),
  ('30000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000002', 'Red',    4),
  ('30000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000002', 'Black',  6),
  ('30000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000003', 'White',  10),
  ('30000000-0000-0000-0000-000000000007', '20000000-0000-0000-0000-000000000003', 'Black',  2),
  ('30000000-0000-0000-0000-000000000008', '20000000-0000-0000-0000-000000000004', 'Blue',   7),
  ('30000000-0000-0000-0000-000000000009', '20000000-0000-0000-0000-000000000004', 'Yellow', 3);

-- ---------- Cart: Chidi has one Blue tote bag in his cart ----------
INSERT INTO carts (id, user_id) VALUES
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004');

INSERT INTO cart_items (id, cart_id, product_colour_id, quantity) VALUES
  ('41000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 1);

-- ---------- Order 1: Bisi, two sellers, order still "paid" because only one item has shipped ----------
-- total = 2 x 8,500,000 + 1 x 12,000,000 = 29,000,000 kobo
INSERT INTO orders (id, buyer_id, total, currency, status, delivery_address) VALUES
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 29000000, 'NGN', 'paid', '12 Allen Avenue, Ikeja, Lagos');

INSERT INTO order_items (id, order_id, seller_id, product_colour_id, product_name, colour_name, unit_price, quantity, status) VALUES
  ('51000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 'Large Tote Bag',   'Blue',  8500000,  2, 'shipped'),
  ('51000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000006', 'Classic Sneakers', 'White', 12000000, 1, 'paid');

INSERT INTO payments (id, order_id, amount, currency, status, payment_reference) VALUES
  ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 29000000, 'NGN', 'failed',    'PAY-0001-ATTEMPT-1'),
  ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 29000000, 'NGN', 'succeeded', 'PAY-0001-ATTEMPT-2');

-- ---------- Order 2: Chidi, delivered, with a review ----------
INSERT INTO orders (id, buyer_id, total, currency, status, delivery_address) VALUES
  ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', 4500000, 'NGN', 'delivered', '5 Adeola Odeku Street, Victoria Island, Lagos');

INSERT INTO order_items (id, order_id, seller_id, product_colour_id, product_name, colour_name, unit_price, quantity, status) VALUES
  ('51000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000004', 'Small Crossbody Bag', 'Red', 4500000, 1, 'delivered');

INSERT INTO payments (id, order_id, amount, currency, status, payment_reference) VALUES
  ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000002', 4500000, 'NGN', 'succeeded', 'PAY-0002-ATTEMPT-1');

INSERT INTO reviews (id, order_item_id, rating, comment) VALUES
  ('70000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000003', 5, 'Lovely bag, arrived on time.');

COMMIT;