# Fashion Marketplace: API Design and Data Modeling

## LinkedIn Post
[Read the LinkedIn post] (https://lnkd.in/p/gewjhUe4)

A design document and data model for a fashion marketplace, with a working Postgres schema that proves the model holds.

## Requirements

**What the product does**

The Fashion Marketplace connects buyers with sellers of fashion products such as clothes, bags, shoes, and accessories. Sellers can list their products with important information such as price, size or dimensions, available colours, stock, and description. Buyers can browse products, add them to their cart, make payment, and place orders.

**Who uses the product**

- Buyers: customers who browse and purchase fashion products.
- Sellers: users who list and manage fashion products and process orders.

**The five most important actions**

1. Seller lists a product with its name, image, category, target audience, price, size or dimensions, colours, stock, description, and material where applicable.
2. Buyer browses and views a product to see its details, price, available colours, size or dimensions, and stock status.
3. Buyer selects an available colour and adds the product to the cart.
4. Buyer places an order and makes payment for the products in the cart.
5. Seller processes the order and marks it as shipped or delivered.

**Product requirements**

Each product listing includes:

- Product name
- One main product image
- Product category
- Target audience
- Price
- Size or dimensions, depending on the product
- Available colours
- Available stock
- Product description
- Material, where applicable

Each product has one defined size or dimension. The buyer does not select a size.

A product can have multiple colour options. Buyers can see the colours available for that product and select their preferred colour before adding it to their cart.

Stock is tracked for each colour. When a colour is out of stock, it can no longer be selected, while colours that still have stock remain available.

Stock reduces automatically when an order is placed. Sellers can increase the stock of a colour when they restock it.

The product clearly shows its price and stock status so buyers know whether it is available before adding it to their cart.

**Reviews**

Buyers can review a product after their order has been delivered.

**Payment**

Payment is part of placing an order. A buyer must complete payment before the order is confirmed.

## Entities

Every table has `id` (a generated UUID), `createdAt` and `updatedAt`. Money is stored as a whole number in kobo, with a currency column beside it.

### 1. User

Stores account information for buyers and sellers.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| name | string | Yes | User's full name |
| email | string | Yes | Unique |
| phone | string | Yes | User's phone number |
| passwordHash | string | Yes | Stores only the hashed password, never the password itself |
| role | enum | Yes | Fixed values: `buyer`, `seller` |
| deletedAt | timestamp | No | Nullable. Soft delete, because orders reference the buyer |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 2. Seller

Stores seller-specific information such as the store or brand name.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| userId | UUID | Yes | Foreign key to User. Unique, to enforce one seller profile per user |
| storeName | string | Yes | Seller's store or brand name |
| details | string | Yes | Seller information |
| deletedAt | timestamp | No | Nullable. Soft delete, so product and order history stays connected |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 3. Product

A fashion product listed by a seller.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| sellerId | UUID | Yes | Foreign key to Seller |
| name | string | Yes | Product name |
| imageUrl | string | Yes | Main product image |
| category | enum | Yes | Fixed values: `bags`, `shoes`, `clothes`, `accessories` |
| targetAudience | enum | Yes | Fixed values: `men`, `women`, `unisex` |
| price | integer | Yes | Whole number in kobo. Must be greater than 0 |
| currency | string | Yes | Currency code, `NGN` |
| sizeOrDimensions | string | Yes | Size or dimensions, depending on the product |
| description | string | Yes | Product description |
| material | string | No | Material, where applicable |
| deletedAt | timestamp | No | Nullable. Soft delete, because old orders may still reference the product |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 4. Product Colour

The available colours of a product, with the stock for each colour. A colour is an option under a product, not a separate product.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| productId | UUID | Yes | Foreign key to Product. Together with `colour`, unique among active colours |
| colour | string | Yes | Colour name |
| stockQuantity | integer | Yes | Current stock for this colour. Cannot be below 0 |
| deletedAt | timestamp | No | Nullable. Soft delete, because a colour that was ordered cannot be hard-deleted |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 5. Cart

A buyer's shopping cart.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| userId | UUID | Yes | Foreign key to User. Unique, to enforce one cart per buyer |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 6. Cart Item

A product colour and quantity added to a cart.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| cartId | UUID | Yes | Foreign key to Cart |
| productColourId | UUID | Yes | Foreign key to Product Colour |
| quantity | integer | Yes | Must be greater than 0 |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

`cartId` and `productColourId` together must be unique, so the same colour cannot appear twice in one cart.

### 7. Order

A purchase made by a buyer.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| buyerId | UUID | Yes | Foreign key to User |
| total | integer | Yes | Whole number in kobo. Must be greater than 0 |
| currency | string | Yes | Currency code, `NGN` |
| status | enum | Yes | Fixed values: `pending`, `paid`, `shipped`, `delivered`, `cancelled` |
| deliveryAddress | string | Yes | Copy of the buyer's delivery address at order time, so it stays correct if the buyer changes their address later |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 8. Order Item

Each product colour included in an order.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| orderId | UUID | Yes | Foreign key to Order |
| sellerId | UUID | Yes | Foreign key to Seller. A deliberate copy of the seller reachable through the product colour, so a seller can list their own order items quickly, even if the product is later removed |
| productColourId | UUID | Yes | Foreign key to Product Colour. `ON DELETE RESTRICT`, because a colour that appears in an order can never be hard-deleted |
| productName | string | Yes | Copy of the product name at purchase time |
| colourName | string | Yes | Copy of the colour name at purchase time |
| unitPrice | integer | Yes | Product price in kobo at purchase time. Must be 0 or more |
| quantity | integer | Yes | Quantity purchased. Must be greater than 0 |
| status | enum | Yes | Fixed values: `pending`, `paid`, `shipped`, `delivered`, `cancelled` |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

`productName`, `colourName` and `unitPrice` are intentionally copied onto the Order Item. This keeps the details of what the buyer purchased correct even if the product name, colour name or price changes later.

### 9. Payment

A payment attempt for an order.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| orderId | UUID | Yes | Foreign key to Order |
| amount | integer | Yes | Whole number in kobo. Must be greater than 0 |
| currency | string | Yes | Currency code, `NGN` |
| status | enum | Yes | Fixed values: `pending`, `succeeded`, `failed` |
| paymentReference | string | Yes | Unique payment reference |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 10. Review

A buyer's review and rating for a purchased item, written after it has been delivered.

| Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| orderItemId | UUID | Yes | Foreign key to Order Item. Unique, so each purchased item has at most one review |
| rating | integer | Yes | Must be between 1 and 5 |
| comment | string | No | Buyer's review comment |
| createdAt | timestamp | Yes | |
| updatedAt | timestamp | Yes | |

### 11. Idempotency Key

Remembers the result of a request that must not be repeated, such as creating a product or placing an order. See the Idempotency section under API Contracts.

| Field | Type | Required? | Notes |
|---|---|---|---|
| userId | UUID | Yes | Foreign key to User. The user who made the request |
| key | string | Yes | The key sent in the `Idempotency-Key` header. `userId` and `key` together are unique |
| requestHash | string | Yes | Hash of the request body |
| storedStatus | integer | Yes | Status code of the original response |
| storedResponse | JSON | Yes | Body of the original response |
| createdAt | timestamp | Yes | Records are deleted after 24 hours |

## Relationships

![Entity relationship diagram](docs/erd.png)

- User → Seller: 1:1. A user can have one seller profile.
- Seller → Product: 1:N. One seller can list many products.
- Product → Product Colour: 1:N. One product can have multiple colours.
- User → Cart: 1:1. One buyer has one cart.
- Cart → Cart Item: 1:N. One cart can contain many items.
- Product Colour → Cart Item: 1:N. A product colour can appear in many cart items.
- User → Order: 1:N. One buyer can place many orders.
- Order → Order Item: 1:N. One order can contain many items.
- Seller → Order Item: 1:N. Each order item belongs to one seller, so a seller only sees their own items.
- Product Colour → Order Item: 1:N. A product colour can appear in many order items.
- Order → Payment: 1:N. One order can have several payment attempts, for example when a payment fails and the buyer retries.
- Order Item → Review: 1:0..1. An order item has zero or one review. A review must belong to an order item.
- User → Review: through Order Item. A buyer is connected to a review through Review → Order Item → Order → User.
- User → Idempotency Key: 1:N. One user can have many stored keys.

## Hard Questions

### Normalisation

Some information is deliberately copied instead of being read from the current Product record.

- **Order Item** stores the product name, colour name, unit price and seller ID at purchase time.
- **Order** stores a copy of the delivery address and the total at order time.

Without these copies, later changes to a product, seller, price or address could make an old order show information that was not true when the purchase was made.

`OrderItem.sellerId` is copied so a seller can list their own order items quickly, even if the product is later removed.

### Money

All money values are stored as whole numbers in minor units, using kobo for NGN, with a separate currency column beside them. This applies to `Product.price`, `Order.total`, `OrderItem.unitPrice` and `Payment.amount`.

### Order status

![Order State Machine](docs/order-state-machine.png)

Order statuses are `pending`, `paid`, `shipped`, `delivered` and `cancelled`.

**Allowed transitions**

- `pending → paid`: payment succeeds.
- `pending → cancelled`: the buyer cancels before payment.
- `paid → shipped`: all Order Items are shipped or delivered.
- `paid → cancelled`: allowed with a refund, but only before any Order Item has shipped, because a shipped item cannot be un-shipped. The refund itself is handled by the payment provider and is outside this design.
- `shipped → delivered`: all Order Items are delivered.

**Forbidden transitions**

- `cancelled → anything`: cancelled is a final state.
- `paid → delivered`: an order cannot skip the shipped state.
- `pending → shipped`: payment must be completed before shipping.
- `paid → pending`: an order cannot go back to pending after payment.
- `shipped → cancelled`: cancellation is not allowed after shipping.
- `delivered → pending`: delivered is a final completed state.
- `delivered → cancelled`: a delivered order cannot be cancelled.

**Rules for orders with several sellers**

- Each Order Item has its own status, because one order can contain products from different sellers.
- Only the seller of an Order Item can mark that item as `shipped` or `delivered`.
- The order stays `paid` until every Order Item is `shipped` or `delivered`, even if some items have already shipped.
- The order becomes `delivered` only when all its Order Items are `delivered`.
- The API updates the Order Item status and the order status in the same database transaction.
- Cancelling an order returns each item's quantity to its Product Colour's stock, in the same transaction.

**What enforces it:** the database enum prevents invalid status values, and the API checks the current status before it allows a transition.

### Time

Every table has `createdAt` and `updatedAt`. The `deletedAt` field is a nullable timestamp. It is empty while the record is active and is set when the record is soft-deleted.

**Soft-deleted with `deletedAt`**

- User: orders reference the buyer, and deletion requests must still be honoured.
- Seller: so seller records connected to products and order history stay available.
- Product: old orders may still reference it.
- Product Colour: `ON DELETE RESTRICT` blocks a hard delete when the colour is in an Order Item. A seller can also set its stock to 0 when they no longer want it available. The `productId + colour` combination is unique only where `deletedAt` is empty, so a seller can add a colour again after removing it.

**Hard-deleted**

- Cart and Cart Item: they are temporary data.

**Never deleted**

- Order, Order Item, Payment and Review: they are the history of what was bought, paid and reviewed.

### Identifiers

All entity IDs are UUIDs, not sequential numbers. UUIDs are hard to guess, so nobody can discover other records by changing a number in a URL or API request.

### Constraints

| Entity | Constraint | Purpose |
|---|---|---|
| User | `email` unique | Prevents two accounts with the same email |
| User | `role` enum: `buyer`, `seller` | Prevents invalid user roles |
| Seller | `userId` unique | Enforces one seller profile per user |
| Product | `price > 0` | Prevents a zero or negative price |
| Product | `category` enum: `bags`, `shoes`, `clothes`, `accessories` | Prevents inconsistent category values |
| Product | `targetAudience` enum: `men`, `women`, `unisex` | Prevents inconsistent audience values |
| Product | `currency = NGN` | Prevents other currencies |
| Product Colour | `productId + colour` unique where `deletedAt` is empty | Prevents the same colour twice on one product |
| Product Colour | `stockQuantity >= 0` | Prevents negative stock |
| Cart | `userId` unique | Enforces one cart per buyer |
| Cart Item | `cartId + productColourId` unique | Prevents the same colour twice in one cart |
| Cart Item | `quantity > 0` | Prevents zero or negative quantities |
| Order | `total > 0` | Prevents a zero or negative total |
| Order | `status` enum: `pending`, `paid`, `shipped`, `delivered`, `cancelled` | Prevents invalid order statuses |
| Order | `currency = NGN` | Prevents other currencies |
| Order Item | `quantity > 0` | Prevents zero or negative quantities |
| Order Item | `unitPrice >= 0` | Prevents negative prices |
| Order Item | `productColourId` `ON DELETE RESTRICT` | Prevents a colour that appears in an order from being hard-deleted |
| Order Item | `status` enum: `pending`, `paid`, `shipped`, `delivered`, `cancelled` | Prevents invalid item statuses |
| Payment | `amount > 0` | Prevents a zero or negative payment amount |
| Payment | `status` enum: `pending`, `succeeded`, `failed` | Prevents invalid payment statuses |
| Payment | `paymentReference` unique | Prevents duplicate payment references |
| Payment | `currency = NGN` | Prevents other currencies |
| Review | `orderItemId` unique | Allows only one review per purchased item |
| Review | `rating` between 1 and 5 | Prevents invalid ratings |
| Idempotency Key | `userId + key` unique | Stops the same request from being processed twice |

The API must also check that an Order Item has status `delivered` before it allows a review to be created.

### Indexes

Indexes are added where they support common queries and are not already created by a unique constraint.

| Table | Index | Purpose |
|---|---|---|
| Product | `sellerId` | Find the products of a seller |
| Product | `(category, targetAudience)` | Filter products by category and target audience |
| Cart Item | `productColourId` | Find carts that contain a specific product colour |
| Order | `buyerId` | Find the orders of a buyer |
| Order Item | `orderId` | Find the items of an order |
| Order Item | `sellerId` | Find the order items of a seller |
| Order Item | `productColourId` | Find the order items for a product colour |
| Payment | `orderId` | Find the payment attempts of an order |

Unique constraints already create indexes, so separate indexes are not needed for `Seller.userId`, `ProductColour(productId, colour)`, `CartItem(cartId, productColourId)`, `Payment.paymentReference` or `Review.orderItemId`.

### Safe stock updates

Stock is reduced with one atomic database update that only succeeds when enough stock is available: `stockQuantity >= quantity`.

If two buyers try to buy the last item at the same time, only the first valid update succeeds. The second update changes nothing, and that buyer receives an out of stock error.

### Impossible states

- A buyer cannot have two carts: `Cart.userId` is unique.
- A colour cannot have negative stock, even if two buyers order the last item at once: `stockQuantity >= 0`, and stock is reduced with an atomic update that requires enough stock.
- A purchased item cannot be reviewed twice: `Review.orderItemId` is unique.
- A product colour used in an order cannot be hard-deleted: `OrderItem.productColourId` uses `ON DELETE RESTRICT`.

## API Contracts

### API conventions

- All API paths start with `/api/v1`.
- Successful responses use:

```json
{
  "data": {},
  "meta": {}
}
```

- Error responses use:

```json
{
  "error": {
    "code": "...",
    "message": "..."
  }
}
```

- List endpoints use `limit`, `offset`, filters and `sort`.
- `limit` defaults to 20 and has a maximum of 100. If `limit` is greater than 100, the API clamps it to 100.
- All money values are sent and stored in kobo.
- Protected endpoints require authentication.

### Idempotency

Product creation, order placement, payments and restocking use an idempotency key to prevent duplicates.The keys are stored in the Idempotency Key table (see Entities).

- The idempotency record and the product or order are created in one database transaction.
- If two identical requests arrive at the same time, the unique `userId + key` constraint prevents both from creating the same product or order. The second request returns `409 REQUEST_IN_PROGRESS`, or waits for the first transaction to finish and then returns the stored response.
- A retry with the same key and the same request body returns the original response, with the same status code and body.
- The same key with a different request body returns `422 IDEMPOTENCY_KEY_REUSED`.
- A missing `Idempotency-Key` header returns `400 IDEMPOTENCY_KEY_REQUIRED`.
- Idempotency records are deleted after 24 hours.

### POST /api/v1/products

**Who can call it:** authenticated sellers only.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the seller |
| Idempotency-Key | Yes | Unique key for this product creation attempt |

**Request body**

| Field | Type | Required? |
|---|---|---|
| name | string | Yes |
| imageUrl | string | Yes |
| category | enum: `bags`, `shoes`, `clothes`, `accessories` | Yes |
| targetAudience | enum: `men`, `women`, `unisex` | Yes |
| price | integer (kobo) | Yes |
| currency | `NGN` | Yes |
| sizeOrDimensions | string | Yes |
| description | string | Yes |
| material | string | No |
| colours | array of objects | Yes |

Each colour contains:

| Field | Type | Required? |
|---|---|---|
| colour | string | Yes |
| stockQuantity | integer | Yes |

A product must have at least one colour. Colour names must be unique within the product.

`sellerId` is taken from the authenticated user's login token and is not accepted in the request body.

**Success response:** `201 Created`. The response includes `sellerId`, `createdAt`, `updatedAt` and a calculated `totalStock`. `totalStock` is not stored in the database. It is calculated by adding the stock quantity of all the product's colours.

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | The `Idempotency-Key` header is missing. |
| 400 | `MALFORMED_JSON` | The request body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a seller. |
| 409 | `REQUEST_IN_PROGRESS` | Another request with the same user and idempotency key is still being processed. |
| 422 | `VALIDATION_ERROR` | A required field is missing or has an invalid value. The message names the field. |
| 422 | `IDEMPOTENCY_KEY_REUSED` | The same key was used with a different request body. |

Examples of `VALIDATION_ERROR` messages:

- `name is required`
- `category is invalid`
- `targetAudience is invalid`
- `currency must be NGN`
- `price must be greater than 0`
- `colours must contain at least one colour`
- `colour names must be unique`
- `stockQuantity must be a whole number, 0 or more`

**Idempotent?** Yes. The API stores the idempotency key, the request hash and the original response. A retry with the same key and body returns the original response instead of creating another product.

### GET /api/v1/products

**Who can call it:** public. Buyers do not need to be logged in.

**Query parameters**

| Parameter | Type | Default | Allowed values |
|---|---|---|---|
| `limit` | integer | 20 | Whole number from 1 to 100. Values above 100 are clamped to 100 |
| `offset` | integer | 0 | Whole number, 0 or greater |
| `category` | string | None | `bags`, `shoes`, `clothes`, `accessories` |
| `targetAudience` | string | None | `men`, `women`, `unisex` |
| `minPrice` | integer | None | Whole number, 0 or greater, in kobo |
| `maxPrice` | integer | None | Whole number, 0 or greater, in kobo |
| `sort` | string | `createdAt` | `price`, `createdAt` |
| `order` | string | `desc` | `asc`, `desc` |

- If `offset` is beyond the total number of matching products, the API returns `200 OK` with an empty `data` array and `hasMore: false`. This is not an error.
- Results are always ordered by the chosen sort field, then by `id`. This gives a stable order when several products share the same price or creation time.
- Only active products are returned. Soft-deleted products are excluded.
- A product stays listed even when all its colours are out of stock. It is shown as out of stock.
- The browse response contains summary information, not the full description. The full description is returned by `GET /api/v1/products/:id`.

**Success response:** `200 OK`

```json
{
  "data": [
    {
      "id": "9d7f2a4e-7d3e-4f8a-9f2e-5a6d7c8b9e10",
      "name": "Large Tote Bag",
      "imageUrl": "https://example.com/tote-bag.jpg",
      "category": "bags",
      "targetAudience": "women",
      "price": 8500000,
      "currency": "NGN",
      "sizeOrDimensions": "Large",
      "colours": [
        { "colour": "Black", "inStock": false },
        { "colour": "Blue", "inStock": true },
        { "colour": "Green", "inStock": true }
      ],
      "totalStock": 8
    }
  ],
  "meta": {
    "total": 1,
    "limit": 20,
    "offset": 0,
    "hasMore": false
  }
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | A query parameter has an invalid value. The message names the parameter. |

Examples:

- `limit must be a whole number between 1 and 100`
- `offset must be a whole number 0 or greater`
- `category is invalid`
- `targetAudience is invalid`
- `minPrice must be a whole number 0 or greater`
- `maxPrice must be a whole number 0 or greater`
- `minPrice cannot be greater than maxPrice`
- `sort must be price or createdAt`
- `order must be asc or desc`

A `limit` above 100 is not an error. It is clamped to 100.

**Safe and idempotent?** Yes. GET does not change any data. Repeating the same request gives the same result for the same underlying data.

### GET /api/v1/products/:id

**Who can call it:** public. Buyers do not need to be logged in.

**Path parameter**

| Parameter | Type | Required? |
|---|---|---|
| `id` | UUID | Yes |

**Success response:** `200 OK`

```json
{
  "data": {
    "id": "9d7f2a4e-7d3e-4f8a-9f2e-5a6d7c8b9e10",
    "sellerId": "7a2b3c4d-5e6f-7a8b-9c10-11d12e13f14a",
    "name": "Large Tote Bag",
    "imageUrl": "https://example.com/tote-bag.jpg",
    "category": "bags",
    "targetAudience": "women",
    "price": 8500000,
    "currency": "NGN",
    "sizeOrDimensions": "Large",
    "description": "Large everyday tote bag.",
    "material": "Leather",
    "colours": [
      { "id": "1b2c3d4e-5f6a-7b8c-9d10-11e12f13a14b", "colour": "Black", "inStock": false },
      { "id": "2b3c4d5e-6f7a-8b9c-0d11-12e13f14a15b", "colour": "Blue", "inStock": true },
      { "id": "3b4c5d6e-7f8a-9b0c-1d12-13e14f15a16b", "colour": "Green", "inStock": true }
    ],
    "totalStock": 8,
    "createdAt": "2026-09-29T10:00:00Z",
    "updatedAt": "2026-09-29T10:00:00Z"
  },
  "meta": {}
}
```

The public detail page shows only `inStock` for each colour, not the exact `stockQuantity`. This avoids exposing the seller's exact inventory while still telling buyers whether a colour is available. `totalStock` is shown because the requirements say buyers must see overall stock availability.

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | The product ID is not a valid UUID. |
| 404 | `NOT_FOUND` | The product does not exist or has been soft-deleted. |

**Safe and idempotent?** Yes. GET does not change any data.

**Product availability decisions**

1. A product with all colours out of stock stays listed. Buyers can still view it, but it is shown as out of stock and no colour can be selected.
2. The public detail page shows only `inStock`, not the exact `stockQuantity`.

### POST /api/v1/cart/items

Adds a product colour to the buyer's cart (Action 3).

**Who can call it:** authenticated buyers only.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the buyer |

**Request body**

| Field | Type | Required? |
|---|---|---|
| productColourId | UUID | Yes |
| quantity | integer | Yes (whole number, 1 or more) |

`buyerId` is taken from the login token, never from the request body.

If the buyer has no cart yet, the API creates one (one cart per buyer).

**If the colour is already in the cart:** the API adds the new quantity to the existing quantity instead of returning an error. A buyer who taps "Add to cart" twice expects two items, and an error would be confusing. The combined quantity must still be within the available stock.

**Stock check:** this check is only an early warning. The real, final stock check happens when the order is placed (see `POST /api/v1/orders`).

**Success response:** `201 Created` when a new cart item is created, `200 OK` when the quantity is added to an existing one.

```json
{
  "data": {
    "id": "5c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f",
    "cartId": "8a7b6c5d-4e3f-2a1b-0c9d-8e7f6a5b4c3d",
    "productColourId": "2b3c4d5e-6f7a-8b9c-0d11-12e13f14a15b",
    "productName": "Large Tote Bag",
    "colour": "Blue",
    "unitPrice": 8500000,
    "currency": "NGN",
    "quantity": 2,
    "createdAt": "2026-09-30T10:00:00Z",
    "updatedAt": "2026-09-30T10:00:00Z"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `MALFORMED_JSON` | The request body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a buyer. |
| 404 | `NOT_FOUND` | The product colour does not exist, or it or its product has been soft-deleted. |
| 409 | `OUT_OF_STOCK` | The colour has 0 stock. |
| 409 | `INSUFFICIENT_STOCK` | The total quantity (already in the cart plus new) is more than the available stock. |
| 422 | `VALIDATION_ERROR` | `productColourId` is missing or not a valid UUID, or `quantity` is missing or not a whole number of 1 or more. The message names the field. |

**Idempotent?** No, and that is deliberate. Sending the same request twice adds the quantity twice. This is acceptable because a cart is low risk: nothing is charged and the buyer can correct the quantity. Exact quantity changes use a separate endpoint that sets the quantity (`PATCH /api/v1/cart/items/:id`), which is idempotent because it sets a value instead of adding to it.

### POST /api/v1/orders

Turns the buyer's cart into an order (Action 4).

**Who can call it:** authenticated buyers only.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the buyer |
| Idempotency-Key | Yes | Unique key for this order attempt |

**Request body**

| Field | Type | Required? |
|---|---|---|
| deliveryAddress | string | Yes |

The items are not sent in the request. They come from the buyer's cart, so a buyer cannot send fake prices or quantities.

**What the API does, in this order, inside ONE database transaction**

1. Find the buyer's cart items. If there are none, stop with `CART_EMPTY`.
2. For each cart item, reduce stock with one atomic update that only succeeds if enough stock is left (`stockQuantity >= quantity`). If any update changes nothing, stop, roll back everything, and return `OUT_OF_STOCK` naming that item.
3. Create the Order with status `pending`, the `deliveryAddress` copied onto it, and the currency.
4. For each cart item, create an Order Item with status `pending`. Copy `productName`, `colourName`, `unitPrice` (the price right now), `quantity` and `sellerId` onto it.
5. Calculate `total` in kobo by adding `unitPrice x quantity` for every Order Item, and save it on the Order.
6. Delete the buyer's cart items.

If any step fails, nothing is saved: no order, no stock change, and the cart stays as it was.

**Payment:** placing an order does not take payment. The order starts as `pending`, and payment is a separate step that moves it to `paid`.

**Unpaid orders:** a `pending` order holds its stock. An order that is still `pending` after 30 minutes is cancelled automatically, and its quantities go back to stock, so unpaid orders cannot lock stock forever.

**Success response:** `201 Created`

```json
{
  "data": {
    "id": "c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8",
    "buyerId": "6f5e4d3c-2b1a-4f9e-8d7c-6b5a4f3e2d1c",
    "status": "pending",
    "total": 17000000,
    "currency": "NGN",
    "deliveryAddress": "12 Allen Avenue, Ikeja, Lagos",
    "items": [
      {
        "id": "d5e6f7a8-b9c0-4d1e-a2f3-a4b5c6d7e8f9",
        "productName": "Large Tote Bag",
        "colourName": "Blue",
        "unitPrice": 8500000,
        "quantity": 2,
        "status": "pending"
      }
    ],
    "createdAt": "2026-09-30T10:05:00Z",
    "updatedAt": "2026-09-30T10:05:00Z"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | The `Idempotency-Key` header is missing. |
| 400 | `MALFORMED_JSON` | The request body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a buyer. |
| 409 | `CART_EMPTY` | The buyer's cart has no items. |
| 409 | `OUT_OF_STOCK` | At least one colour does not have enough stock. The message names the product and colour, for example "Large Tote Bag (Blue) does not have enough stock". Also returned when the product or colour has been removed.|
| 409 | `REQUEST_IN_PROGRESS` | Another request with the same buyer and idempotency key is still being processed. |
| 422 | `VALIDATION_ERROR` | `deliveryAddress` is missing or empty. The message names the field. |
| 422 | `IDEMPOTENCY_KEY_REUSED` | The same key was used with a different request body. |

**Idempotent?** Yes, using the `Idempotency-Key` header, with the same rules as product creation. A retry with the same key and body returns the original response and does not create a second order. A key used with a different body returns `IDEMPOTENCY_KEY_REUSED`. Without the key, a buyer who double-clicks "Place order" could get two orders and have stock reduced twice.

### PATCH /api/v1/order-items/:id

A seller updates the status of one of their own order items (Action 5). The item moves from `paid` to `shipped`, and later from `shipped` to `delivered`.

**Who can call it:** authenticated sellers only, and only for order items that belong to them (`OrderItem.sellerId` matches the seller in the login token).

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the seller |

**Path parameter**

| Parameter | Type | Required? |
|---|---|---|
| id | UUID | Yes |

**Request body**

| Field | Type | Required? |
|---|---|---|
| status | enum: `shipped`, `delivered` | Yes |

**Allowed item transitions**

| From | To | Meaning |
|---|---|---|
| paid | shipped | The seller has sent the item out. |
| shipped | delivered | The item has reached the buyer. |

Everything else is forbidden. For example: `pending → shipped` (the order is unpaid), `paid → delivered` (skips shipped), `delivered → shipped` (cannot go backwards), and anything from `cancelled`.

An item starts as `pending` when the order is placed. When payment succeeds, the API sets the order to `paid` and all its items to `paid` in one transaction. This endpoint only handles what happens after that.

**What the API does, in this order, inside ONE database transaction**

1. Lock the parent order row, so two sellers updating items of the same order at the same moment take turns.
2. Find the order item. If it does not exist, or belongs to another seller, stop with `NOT_FOUND`.
3. If the requested status is the same as the current status, change nothing and return the current state.
4. Check the transition is allowed. If not, stop with `INVALID_TRANSITION`.
5. Update the item's status and `updatedAt`.
6. Read all items of that order and decide the order status:
   - If every item is `shipped` or `delivered`, and the order is `paid`, set the order to `shipped`.
   - If every item is `delivered`, set the order to `delivered`.
   - Otherwise the order status stays as it is. For example, it stays `paid` while some items have not shipped.

If any step fails, nothing is saved.

**Race condition and how it is prevented:** two sellers ship the last two items of the same order at the same moment. Without a lock, both transactions could read the other item as "not shipped yet", and the order would never move to `shipped`. Locking the order row in step 1 makes the second transaction wait until the first has finished. It then sees the first item as shipped and updates the order correctly.

**Why a seller who does not own the item gets 404, not 403:** a `403` would confirm that the item exists. A `404` reveals nothing about other sellers' orders.

**Success response:** `200 OK`

```json
{
  "data": {
    "id": "d5e6f7a8-b9c0-4d1e-a2f3-a4b5c6d7e8f9",
    "orderId": "c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8",
    "sellerId": "7a2b3c4d-5e6f-7a8b-9c10-11d12e13f14a",
    "productName": "Large Tote Bag",
    "colourName": "Blue",
    "unitPrice": 8500000,
    "quantity": 2,
    "status": "shipped",
    "orderStatus": "paid",
    "updatedAt": "2026-09-30T14:20:00Z"
  },
  "meta": {}
}
```

`orderStatus` is the order's current status after the update, so the client can see whether this change completed the order.

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | The item ID in the path is not a valid UUID, or the body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a seller. |
| 404 | `NOT_FOUND` | The order item does not exist, or belongs to another seller. |
| 409 | `INVALID_TRANSITION` | The change is not allowed. The message names both statuses, for example "cannot change item from pending to shipped". |
| 422 | `VALIDATION_ERROR` | `status` is missing, or is not `shipped` or `delivered`. The message names the field. |

**Idempotent?** Yes. The request sets a status, it does not add to anything. If a seller sends `shipped` for an item that is already `shipped`, the API returns `200 OK` with the current state and changes nothing. A double-click or retry cannot ship an item twice or change the order twice. No `Idempotency-Key` header is needed.

### POST /api/v1/orders/:id/payments

A buyer pays for a `pending` order. This starts one payment attempt (part of Action 4).

**Who can call it:** the authenticated buyer who owns the order. Any other user gets `404 NOT_FOUND`.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the buyer |
| Idempotency-Key | Yes | Unique key for this payment attempt. A double-click must never start two payments |

**Path parameter**

| Parameter | Type | Required? |
|---|---|---|
| id | UUID | Yes (the order ID) |

**Request body:** none. The amount and currency always come from the order, never from the client, so a buyer cannot change what they pay.

**What the API does, in this order**

1. Lock the order row and check the buyer owns it. If not, stop with `NOT_FOUND`.
2. Check the order status is `pending`. If not, stop with `ORDER_NOT_PAYABLE`.
3. Check the order has no payment attempt that is still `pending`. If it has, stop with `PAYMENT_IN_PROGRESS`.
4. Create a Payment with status `pending`, the order's total as `amount`, and a new unique `paymentReference`.
5. Call the payment provider to create a checkout session (this call may fail and may be slow). If it fails, set the Payment to `failed` and return `PAYMENT_PROVIDER_ERROR`. The order stays `pending`, so the buyer can try again.
6. Return the checkout link. The buyer finishes paying on the provider's page.

The order does not become `paid` here. Only the provider's confirmation (the webhook below) can do that.

**Success response:** `201 Created`

```json
{
  "data": {
    "id": "e6f7a8b9-c0d1-4e2f-b3a4-b5c6d7e8f9a0",
    "orderId": "c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8",
    "amount": 17000000,
    "currency": "NGN",
    "status": "pending",
    "paymentReference": "PAY-8F3K29XQ",
    "checkoutUrl": "https://checkout.provider.example/PAY-8F3K29XQ"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | The `Idempotency-Key` header is missing. |
| 400 | `VALIDATION_ERROR` | The order ID is not a valid UUID. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a buyer. |
| 404 | `NOT_FOUND` | The order does not exist or belongs to another buyer. |
| 409 | `ORDER_NOT_PAYABLE` | The order is not `pending` (already paid, cancelled, shipped or delivered). |
| 409 | `PAYMENT_IN_PROGRESS` | The order already has a payment attempt that is still `pending`. |
| 409 | `REQUEST_IN_PROGRESS` | Another request with the same buyer and key is still being processed. |
| 422 | `IDEMPOTENCY_KEY_REUSED` | The same key was used with a different request. |
| 502 | `PAYMENT_PROVIDER_ERROR` | The payment provider could not create the checkout session. |

**Idempotent?** Yes, using the `Idempotency-Key` header, with the same rules as product creation. A retry returns the original response and does not start a second payment.

---

### POST /api/v1/payments/webhook

The payment provider calls this endpoint to tell the marketplace whether a payment succeeded or failed. Users never call it.

**Who can call it:** only the payment provider. Every request must carry a signature header (`X-Signature`) that the API checks against a secret shared with the provider. A request with a missing or wrong signature is rejected.

**Request body**

| Field | Type | Required? |
|---|---|---|
| paymentReference | string | Yes |
| status | enum: `succeeded`, `failed` | Yes |
| amount | integer (kobo) | Yes |

**What the API does, in this order, inside ONE database transaction**

1. Check the signature. If it is wrong, stop with `INVALID_SIGNATURE`.
2. Find the Payment by `paymentReference`. If it does not exist, stop with `NOT_FOUND`.
3. If the Payment is already `succeeded` or `failed`, change nothing and return `200 OK`. Providers send the same event more than once, so repeats must be safe.
4. Check `amount` equals the Payment's amount. If not, stop with `AMOUNT_MISMATCH` and change nothing.
5. If `status` is `failed`: set the Payment to `failed`. The order stays `pending` and the buyer can try again.
6. If `status` is `succeeded`: lock the order, set the Payment to `succeeded`, and then:
   - if the order is `pending`, set the order to `paid` and all its Order Items to `paid`;
   - if the order was already cancelled (for example, auto-cancelled after 30 minutes while the buyer was paying), keep the Payment as `succeeded` and flag it for a refund. The refund itself is outside this design.

**Success response:** `200 OK`

```json
{
  "data": { "received": true },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `MALFORMED_JSON` | The body is not valid JSON. |
| 401 | `INVALID_SIGNATURE` | The signature is missing or wrong. |
| 404 | `NOT_FOUND` | No payment has this reference. |
| 422 | `VALIDATION_ERROR` | A required field is missing or invalid. The message names the field. |
| 422 | `AMOUNT_MISMATCH` | The amount does not match the payment. |

**Idempotent?** Yes. A payment that is already `succeeded` or `failed` is never changed again, so the same event sent twice has the same result as sending it once.

---

### POST /api/v1/orders/:id/cancel

A buyer cancels an order. This is a POST and not a DELETE because an order is never deleted. It stays as history with status `cancelled`.

**Who can call it:** the authenticated buyer who owns the order. Any other user gets `404 NOT_FOUND`.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the buyer |

**Request body:** none.

**What the API does, in this order, inside ONE database transaction**

1. Lock the order row and check the buyer owns it. If not, stop with `NOT_FOUND`.
2. If the order is already `cancelled`, change nothing and return it.
3. If the order is `pending`: set it to `cancelled`.
4. If the order is `paid` and no Order Item has shipped: set it to `cancelled`.
5. Otherwise (the order is `paid` and any item has shipped, or the order is `shipped` or `delivered`), stop with `ORDER_NOT_CANCELLABLE`.
6. Set all its Order Items to `cancelled`.
7. Return each item's quantity to its Product Colour's stock.
8. If the order was `paid`, request a refund for its succeeded payment. The refund itself is handled by the payment provider and is outside this design.

If any step fails, nothing is saved.

**Success response:** `200 OK`

```json
{
  "data": {
    "id": "c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8",
    "status": "cancelled",
    "refundRequested": true,
    "updatedAt": "2026-09-30T15:00:00Z"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | The order ID is not a valid UUID. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a buyer. |
| 404 | `NOT_FOUND` | The order does not exist or belongs to another buyer. |
| 409 | `ORDER_NOT_CANCELLABLE` | An item has already shipped, or the order is `shipped` or `delivered`. The message names the current status. |

**Idempotent?** Yes. Cancelling an order that is already `cancelled` returns `200 OK` with the current state and changes nothing, so stock is never returned twice.

---

### POST /api/v1/order-items/:id/reviews

A buyer reviews an item they bought, after it has been delivered.

**Who can call it:** the authenticated buyer who owns the order that contains the item. Any other user gets `404 NOT_FOUND`.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the buyer |

**Request body**

| Field | Type | Required? |
|---|---|---|
| rating | integer | Yes (1 to 5) |
| comment | string | No |

**What the API does, in this order**

1. Find the Order Item and check the buyer owns its order. If not, stop with `NOT_FOUND`.
2. Check the item's status is `delivered`. If not, stop with `ITEM_NOT_DELIVERED`.
3. Save the review. The unique `orderItemId` rule stops a second review for the same purchase, and the API returns `REVIEW_ALREADY_EXISTS`.

A review belongs to the purchase (the Order Item), not directly to the product. This is why a review cannot exist without a delivered order.

**Success response:** `201 Created`

```json
{
  "data": {
    "id": "f7a8b9c0-d1e2-4f3a-84b5-c6d7e8f9a0b1",
    "orderItemId": "d5e6f7a8-b9c0-4d1e-a2f3-a4b5c6d7e8f9",
    "rating": 5,
    "comment": "Lovely bag, arrived on time.",
    "createdAt": "2026-10-02T09:30:00Z"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `MALFORMED_JSON` | The body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a buyer. |
| 404 | `NOT_FOUND` | The order item does not exist or is not in this buyer's order. |
| 409 | `ITEM_NOT_DELIVERED` | The item's status is not `delivered`. |
| 409 | `REVIEW_ALREADY_EXISTS` | This item already has a review. |
| 422 | `VALIDATION_ERROR` | `rating` is missing or not a whole number from 1 to 5. The message names the field. |

**Idempotent?** No key is needed. Sending the same request twice is safe, because the unique `orderItemId` rule makes the second one fail with `REVIEW_ALREADY_EXISTS`, so only one review is ever saved.

---

### POST /api/v1/product-colours/:id/restock

A seller adds stock to one of their colours.

**Who can call it:** the authenticated seller who owns the product. Any other user gets `404 NOT_FOUND`.

**Headers**

| Header | Required? | Description |
|---|---|---|
| Authorization | Yes | Login token used to identify the seller |
| Idempotency-Key | Yes | Unique key for this restock. A double-click must not add the stock twice |

**Request body**

| Field | Type | Required? |
|---|---|---|
| quantity | integer | Yes (whole number, 1 or more) |

**Why this adds stock instead of setting a new number:** if a seller sets the stock to 10 at the same moment a buyer's order takes one item, a "set" would overwrite the order's change and stock would be wrong. An "add" is applied to the current number inside the database (`stockQuantity = stockQuantity + quantity`), so both changes are kept.

**Success response:** `200 OK`. The seller sees the exact stock, which buyers never see.

```json
{
  "data": {
    "id": "2b3c4d5e-6f7a-8b9c-0d11-12e13f14a15b",
    "productId": "9d7f2a4e-7d3e-4f8a-9f2e-5a6d7c8b9e10",
    "colour": "Blue",
    "stockQuantity": 15,
    "updatedAt": "2026-09-30T16:00:00Z"
  },
  "meta": {}
}
```

**Errors**

| Status | Code | When |
|---|---|---|
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | The `Idempotency-Key` header is missing. |
| 400 | `MALFORMED_JSON` | The body is not valid JSON. |
| 401 | `UNAUTHENTICATED` | The user is not logged in or the token is invalid. |
| 403 | `FORBIDDEN` | The logged-in user is not a seller. |
| 404 | `NOT_FOUND` | The colour does not exist, was removed, or belongs to another seller's product. |
| 409 | `REQUEST_IN_PROGRESS` | Another request with the same seller and key is still being processed. |
| 422 | `VALIDATION_ERROR` | `quantity` is missing or not a whole number of 1 or more. The message names the field. |
| 422 | `IDEMPOTENCY_KEY_REUSED` | The same key was used with a different request. |

**Idempotent?** Yes, using the `Idempotency-Key` header. A retry returns the original response and does not add the stock twice.

---

### Other endpoints

These follow the same conventions as the contracts above: the `data` and `meta` envelope, the same error shape, `404` (not `403`) when a record belongs to someone else, and the same pagination rules. Every list returns `meta` with `total`, `limit`, `offset` and `hasMore`.

| Endpoint | Who | What it does | Errors | Idempotent? |
|---|---|---|---|---|
| `PATCH /api/v1/products/:id` | Seller who owns the product | Updates any of: `name`, `imageUrl`, `category`, `targetAudience`, `price`, `sizeOrDimensions`, `description`, `material`. At least one field is required. `sellerId`, `currency` and stock cannot be changed here (stock changes use restock). A new price only affects future orders, because old Order Items keep their own copy. Returns the updated product | 400 `MALFORMED_JSON`, 401, 403, 404 (not found, removed, or not yours), 422 `VALIDATION_ERROR` | Yes, it sets values |
| `DELETE /api/v1/products/:id` | Seller who owns the product | Soft-deletes the product by setting `deletedAt`. Old orders are not affected. Its colours stop being available, and an order that contains a removed product returns `409 OUT_OF_STOCK` naming the item. Returns `204 No Content` | 400 `VALIDATION_ERROR`, 401, 403, 404 | Yes in effect. A second call returns `404`, and the state is the same |
| `DELETE /api/v1/product-colours/:id` | Seller who owns the product | Soft-deletes a colour by setting `deletedAt`. The colour can be added again later. Returns `204 No Content` | 400 `VALIDATION_ERROR`, 401, 403, 404 | Yes in effect, same as above |
| `GET /api/v1/seller/products` | Seller | Lists the seller's own products with the exact `stockQuantity` of each colour. Filters: `category`, `targetAudience`. Sort: `price`, `createdAt` | 400 `VALIDATION_ERROR` (bad query), 401, 403 | Yes, safe |
| `GET /api/v1/cart` | Buyer | Returns the buyer's cart with each item's name, colour, current price, quantity, line total, and an `available` flag. Also returns `cartTotal`. A buyer with no cart gets an empty `items` list | 401, 403 | Yes, safe |
| `PATCH /api/v1/cart/items/:id` | Buyer who owns the cart | Sets the quantity of a cart item. Body: `quantity` (whole number, 1 or more). Checked against available stock. Returns the updated item | 400 `MALFORMED_JSON`, 401, 403, 404, 409 `OUT_OF_STOCK`, 409 `INSUFFICIENT_STOCK`, 422 `VALIDATION_ERROR` | Yes, it sets a value |
| `DELETE /api/v1/cart/items/:id` | Buyer who owns the cart | Removes an item from the cart (cart items are hard-deleted). Returns `204 No Content` | 400 `VALIDATION_ERROR`, 401, 403, 404 | Yes in effect. A second call returns `404`, and the state is the same |
| `GET /api/v1/orders` | Buyer | Lists the buyer's own orders. Filter: `status`. Sort: `createdAt` (default, newest first). Uses `limit` and `offset` | 400 `VALIDATION_ERROR` (bad query), 401, 403 | Yes, safe |
| `GET /api/v1/orders/:id` | Buyer who owns the order | Returns one order with its items (including each item's status) and its payment attempts | 400 `VALIDATION_ERROR`, 401, 403, 404 | Yes, safe |
| `GET /api/v1/seller/order-items` | Seller | Lists only the seller's own order items, using the `sellerId` copy on each item. Filter: `status`. Sort: `createdAt`. Shows the delivery address of paid orders only | 400 `VALIDATION_ERROR` (bad query), 401, 403 | Yes, safe |
| `GET /api/v1/products/:id/reviews` | Public | Lists the reviews of a product, newest first. Each review shows `rating`, `comment`, `createdAt` and the buyer's first name only. `meta` also includes `averageRating` | 400 `VALIDATION_ERROR`, 404 (product not found or removed) | Yes, safe |

### Over-fetching

**Endpoint chosen:** `GET /api/v1/products` (the browse list).

**The problem:** a product card on the browse page only needs the product's name, image and price. But each REST result also carries category, target audience, size, the full colours list and `totalStock`. A buyer scrolling through 20 products downloads all of that for every card, even though the card never shows most of it.

**REST response (one item from the list)**

```json
{
  "id": "9d7f2a4e-7d3e-4f8a-9f2e-5a6d7c8b9e10",
  "name": "Large Tote Bag",
  "imageUrl": "https://example.com/tote-bag.jpg",
  "category": "bags",
  "targetAudience": "women",
  "price": 8500000,
  "currency": "NGN",
  "sizeOrDimensions": "Large",
  "colours": [
    { "colour": "Black", "inStock": false },
    { "colour": "Blue", "inStock": true },
    { "colour": "Green", "inStock": true }
  ],
  "totalStock": 8
}
```

**GraphQL query for the same need:** the client asks only for the three fields the card shows.

```graphql
query {
  products(limit: 20) {
    id
    name
    imageUrl
    price
  }
}
```

**What GraphQL would return**

```json
{
  "data": {
    "products": [
      {
        "id": "9d7f2a4e-7d3e-4f8a-9f2e-5a6d7c8b9e10",
        "name": "Large Tote Bag",
        "imageUrl": "https://example.com/tote-bag.jpg",
        "price": 8500000
      }
    ]
  }
}
```

**When REST is still fine**

- The extra fields are small. Each product adds only a few hundred bytes, so the saving is real but not large.
- REST can already shrink the response without GraphQL, for example with a `?fields=name,imageUrl,price` query parameter.
- REST is simpler to build, cache, document and test. This follows the class guidance that REST is the right choice for an MVP. GraphQL adds a schema, a resolver layer and harder caching, and a small team building a first version should not pay that cost early.

**Decision:** use REST for the MVP. Switch to GraphQL when one of these happens:

1. Several clients (web, mobile app, seller dashboard) need very different shapes of the same data, and adding a special endpoint or `fields` option for each becomes hard to maintain.
2. One screen needs three or more separate requests to load, for example the product, its seller and its reviews, and the extra round trips make the page noticeably slow.

The trigger is how many different clients and screens need different data shapes, not the number of users.

### Real-time

**Place chosen:** a buyer watches their order move from `paid` to `shipped` to `delivered` without refreshing the page or repeatedly asking the server.

**Tool chosen:** Server-Sent Events (SSE).

**Why SSE and not WebSockets**

- SSE is one-directional: the server sends updates to the client. WebSockets are bidirectional: both sides can send messages at any time.
- Here the buyer only listens. They send nothing back while watching the order, so two-way communication is not needed.
- SSE runs over normal HTTP and the browser reconnects automatically if the connection drops. That makes it simpler to build and to run than WebSockets.

**Endpoint:** `GET /api/v1/orders/:id/events`

- Who can call it: the authenticated buyer who owns the order. Any other user gets `404 NOT_FOUND`.
- Response: `200 OK` with `Content-Type: text/event-stream`. The connection stays open and the server sends an event each time the order changes.
- The browser's built-in `EventSource` cannot send an `Authorization` header, so this endpoint accepts the login token through a secure cookie (or a short-lived token). The client must not put the normal login token in the URL.

**Example event** sent when a seller marks an item as shipped:

```
event: order.item.shipped
data: {"orderId":"c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8","itemId":"d5e6f7a8-b9c0-4d1e-a2f3-a4b5c6d7e8f9","itemStatus":"shipped","orderStatus":"paid"}
```

A second event is sent when the last item ships and the order itself changes:

```
event: order.status.changed
data: {"orderId":"c4d5e6f7-a8b9-4c0d-91e2-f3a4b5c6d7e8","orderStatus":"shipped"}
```

**When I would switch to WebSockets:** if the product later needs two-way messaging, for example a live chat between buyer and seller, because then the client also needs to send messages to the server over the same connection.

## Schema Proof

This section proves the data model works. I implemented only the schema, then ran queries against it and tried to break it.

The database is Postgres, running in Docker. Table and column names use `snake_case` (for example `stock_quantity`), while the design sections above use `camelCase`.

### Files

| File | What it does |
|---|---|
| `db/migrations/001_init.sql` | Creates the enums, 11 tables, constraints and indexes |
| `db/seed.sql` | Loads a small dataset: 2 sellers, 2 buyers, 4 products with colours, 1 cart, 2 orders and 1 review |
| `db/queries.sql` | One query for each of the five important actions |
| `db/explain.sql` | Query plans for the two heaviest queries |
| `db/invalid_inserts.sql` | Three invalid states the database must reject |

### How to run it

Start Postgres and create the database:

```
docker run --name fashion-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
docker exec -it fashion-db psql -U postgres -c "CREATE DATABASE fashion_marketplace;"
```

Run each file (PowerShell):

```
Get-Content db\migrations\001_init.sql | docker exec -i fashion-db psql -U postgres -d fashion_marketplace
Get-Content db\seed.sql | docker exec -i fashion-db psql -U postgres -d fashion_marketplace
Get-Content db\queries.sql | docker exec -i fashion-db psql -U postgres -d fashion_marketplace
Get-Content db\explain.sql | docker exec -i fashion-db psql -U postgres -d fashion_marketplace
Get-Content db\invalid_inserts.sql | docker exec -i fashion-db psql -U postgres -d fashion_marketplace
```

`seed.sql` clears the tables first, so it can be run again at any time. To run `queries.sql` a second time, run `seed.sql` first.

### The five queries

Each query answers one of the five important actions.

| Action | What the query does |
|---|---|
| 1. Seller lists a product | Inserts the product and its colours with stock in one transaction |
| 2. Buyer browses products | Filters by category, audience and price, sorts by price, and paginates. Returns each colour's `inStock` and the total stock |
| 3. Buyer adds a colour to the cart | Inserts the cart item, or adds to the quantity if it is already there. Only works if the colour exists and has stock |
| 4. Buyer places an order | In one transaction: snapshots the cart, reduces stock only where enough is left, creates the order and order items with copied names and prices, and empties the cart |
| 5. Seller ships an order item | In one transaction: locks the order, ships the seller's own item, and moves the order to `shipped` only if every item has shipped |

Output of the five queries:

![Output of the five queries](docs/screenshots/queries-output.png)

### Query plans

I checked the plans of the two heaviest queries: browsing products (Action 2) and the cart snapshot used when placing an order (Action 4).

The test data has only a few rows, so Postgres would normally read the whole table instead of using an index. To show that my indexes can be used, `explain.sql` turns off sequential scans for the session with `SET enable_seqscan = off`. With real data volumes Postgres chooses the index on its own.

**Browse products** uses the index `products_category_audience_idx`:

![Query plan for browsing products](docs/screenshots/plan-browse.png)

**Cart snapshot when placing an order** uses the index `cart_items_cart_colour_unique`:

![Query plan for the cart snapshot](docs/screenshots/plan-cart-snapshot.png)

### Invalid states the database rejects

I tried three invalid actions. The database rejected each one.

| # | Invalid state I tried | What stopped it | Real-world mistake it prevents |
|---|---|---|---|
| 1 | A second cart for the same buyer | Unique constraint `carts_user_id_unique` | A buyer with two carts, so items and totals get mixed up |
| 2 | A product with a price of 0 | Check constraint `products_price_positive` | A seller listing a product for free by mistake |
| 3 | Deleting a colour that appears in an order | Foreign key `order_items_product_colour_id_fkey` (`ON DELETE RESTRICT`) | Losing the record of what a buyer purchased |

Screenshot of the three errors:

![The three rejected invalid states](docs/screenshots/invalid-inserts.png)

### What the schema makes impossible

- A buyer cannot have two carts (`carts_user_id_unique`).
- A colour cannot go below zero stock, even if two buyers order the last item at once (`product_colours_stock_not_negative`).
- A purchased item cannot be reviewed twice (`reviews_order_item_unique`).
- A colour used in an order cannot be hard-deleted (`ON DELETE RESTRICT`).
- A seller cannot have two seller profiles (`sellers_user_id_unique`).
- A product cannot have the same active colour twice (the partial unique index `product_colours_product_colour_unique`).

