-- 001_init.sql
-- Fashion Marketplace schema (Postgres 13 or newer).
-- Money is stored as whole numbers in kobo, with a currency column beside it.
-- IDs are generated UUIDs. updated_at is set by the API on every change.

BEGIN;

-- ---------- Enums (fixed values, no free text) ----------
CREATE TYPE user_role AS ENUM ('buyer', 'seller');
CREATE TYPE product_category AS ENUM ('bags', 'shoes', 'clothes', 'accessories');
CREATE TYPE target_audience AS ENUM ('men', 'women', 'unisex');
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled');
CREATE TYPE order_item_status AS ENUM ('pending', 'paid', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed');

-- ---------- Users and sellers ----------
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role          user_role NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at    TIMESTAMPTZ,
  CONSTRAINT users_email_unique UNIQUE (email)
);

CREATE TABLE sellers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  store_name  TEXT NOT NULL,
  details     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ,
  CONSTRAINT sellers_user_id_unique UNIQUE (user_id)  -- one seller profile per user
);

-- ---------- Products and colours ----------
CREATE TABLE products (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id          UUID NOT NULL REFERENCES sellers(id),
  name               TEXT NOT NULL,
  image_url          TEXT NOT NULL,
  category           product_category NOT NULL,
  target_audience    target_audience NOT NULL,
  price              BIGINT NOT NULL,
  currency           TEXT NOT NULL,
  size_or_dimensions TEXT NOT NULL,
  description        TEXT NOT NULL,
  material           TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at         TIMESTAMPTZ,
  CONSTRAINT products_price_positive CHECK (price > 0),
  CONSTRAINT products_currency_ngn CHECK (currency = 'NGN')
);

CREATE TABLE product_colours (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     UUID NOT NULL REFERENCES products(id),
  colour         TEXT NOT NULL,
  stock_quantity INTEGER NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ,
  CONSTRAINT product_colours_stock_not_negative CHECK (stock_quantity >= 0)
);

-- A product cannot have the same colour twice, but a removed colour can be added again.
CREATE UNIQUE INDEX product_colours_product_colour_unique
  ON product_colours (product_id, colour)
  WHERE deleted_at IS NULL;

-- ---------- Carts ----------
CREATE TABLE carts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT carts_user_id_unique UNIQUE (user_id)  -- one cart per buyer
);

CREATE TABLE cart_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id           UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  product_colour_id UUID NOT NULL REFERENCES product_colours(id),
  quantity          INTEGER NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT cart_items_quantity_positive CHECK (quantity > 0),
  CONSTRAINT cart_items_cart_colour_unique UNIQUE (cart_id, product_colour_id)
);

-- ---------- Orders ----------
CREATE TABLE orders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id         UUID NOT NULL REFERENCES users(id),
  total            BIGINT NOT NULL,
  currency         TEXT NOT NULL,
  status           order_status NOT NULL DEFAULT 'pending',
  delivery_address TEXT NOT NULL,  -- deliberate copy taken at order time
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT orders_total_positive CHECK (total > 0),
  CONSTRAINT orders_currency_ngn CHECK (currency = 'NGN')
);

CREATE TABLE order_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID NOT NULL REFERENCES orders(id),
  seller_id         UUID NOT NULL REFERENCES sellers(id),  -- deliberate copy so sellers can list their items fast
  product_colour_id UUID NOT NULL REFERENCES product_colours(id) ON DELETE RESTRICT,
  product_name      TEXT NOT NULL,  -- deliberate copies taken at purchase time
  colour_name       TEXT NOT NULL,
  unit_price        BIGINT NOT NULL,
  quantity          INTEGER NOT NULL,
  status            order_item_status NOT NULL DEFAULT 'pending',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT order_items_quantity_positive CHECK (quantity > 0),
  CONSTRAINT order_items_unit_price_not_negative CHECK (unit_price >= 0)
);

-- ---------- Payments ----------
CREATE TABLE payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID NOT NULL REFERENCES orders(id),
  amount            BIGINT NOT NULL,
  currency          TEXT NOT NULL,
  status            payment_status NOT NULL DEFAULT 'pending',
  payment_reference TEXT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT payments_amount_positive CHECK (amount > 0),
  CONSTRAINT payments_currency_ngn CHECK (currency = 'NGN'),
  CONSTRAINT payments_reference_unique UNIQUE (payment_reference)
);

-- ---------- Reviews ----------
CREATE TABLE reviews (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id UUID NOT NULL REFERENCES order_items(id),
  rating        SMALLINT NOT NULL,
  comment       TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT reviews_order_item_unique UNIQUE (order_item_id),  -- one review per purchase
  CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5)
);

-- ---------- Idempotency keys (product creation and order placement) ----------
CREATE TABLE idempotency_keys (
  user_id         UUID NOT NULL REFERENCES users(id),
  key             TEXT NOT NULL,
  request_hash    TEXT NOT NULL,
  stored_status   INTEGER NOT NULL,
  stored_response JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, key)
);

-- ---------- Indexes ----------
-- Unique constraints above already create their own indexes.
CREATE INDEX products_seller_id_idx ON products (seller_id);
CREATE INDEX products_category_audience_idx ON products (category, target_audience);
CREATE INDEX cart_items_product_colour_id_idx ON cart_items (product_colour_id);
CREATE INDEX orders_buyer_id_idx ON orders (buyer_id);
CREATE INDEX order_items_order_id_idx ON order_items (order_id);
CREATE INDEX order_items_seller_id_idx ON order_items (seller_id);
CREATE INDEX order_items_product_colour_id_idx ON order_items (product_colour_id);
CREATE INDEX payments_order_id_idx ON payments (order_id);

COMMIT;