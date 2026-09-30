#  API Design and Data Modeling

## Requirements
**What the product does:**
The Fashion Marketplace connects buyers with sellers of fashion products such as clothes, bags, shoes, and accessories. Sellers can list their products with important information such as price, size or dimensions, available colours, stock, and description, while buyers can browse products, add them to their cart, make payment, and place orders.

**Who Uses the Product**
The marketplace will have two main types of users:
- Buyers: Customers who browse and purchase fashion products.
- Sellers: Users who list and manage fashion products and process orders.

**Main Actions**
The main actions in the marketplace are:
1. Seller lists a product with its name, image, category, target audience, price, size or dimensions, colours, stock, description, and material where applicable.
2. Buyer browses and views a product to see its details, price, available colours, size or dimensions, and stock status.
3. Buyer selects an available colour and adds the product to the cart.
4. Buyer places an order and makes payment for the product in the cart.
5. Seller processes the order and marks it as shipped or delivered.
6. Seller restocks a colour when its available stock needs to be increased.

**Product Requirements**
Each product listing should include:
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

Each product will have one defined size or dimension. The buyer does not select a size for the product.

A product can have multiple colour options. Buyers can see the colours available for that particular product and select their preferred colour before adding it to their cart.

Stock should be tracked for each available colour. When a particular colour is out of stock, it should no longer be available for selection, while colours that still have stock remain available.

Stock should automatically reduce when an order is placed. Sellers can increase the stock when they restock a colour.

The product should clearly show its price and stock status so buyers know whether it is available before adding it to their cart.

**Reviews**
Buyers can review a product after their order has been delivered.

**Payment**
Payment is part of placing an order. A buyer must complete payment before the order is confirmed.

## Entities
The main entities in the Fashion Marketplace are:

1. User
   Stores account information for buyers and sellers, such as name, email, phone number, password, and role.
   | Field | Type | Required? | Notes |
|---|---|---|---|
| id | UUID | Yes | Generated, not sequential |
| name | String | Yes | User's full name |
| email | String | Yes | Unique |
| phone | String | Yes | User's phone number |
| passwordHash | String | Yes | Stores only the hashed password, never the password itself |
| role | Enum | Yes | Fixed values: `buyer`, `seller` |
| createdAt | Timestamp | Yes | |
| updatedAt | Timestamp | Yes | |

2. Seller
   Stores seller-specific information such as store or brand name and seller details.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
userId| UUID| yes| Foreign key to User. Must be unique to enforce the 1:1 relationship
storeName| string| yes| Seller's store or brand name
details| string| yes| Seller information
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

3. Product
   Represents a fashion product listed by a seller. It includes the product name, image, category, target audience, price, size or dimensions, description, and material where applicable.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
sellerId| UUID| yes| Foreign key to Seller
name| string| yes| Product name
imageUrl| string| yes| Main product image
category| enum| yes| Fixed values: "bags", "shoes", "clothes", "accessories"
targetAudience| enum| yes| Fixed values: "men", "women", "unisex"
price| integer| yes| Whole number in kobo. Must be greater than 0
currency| string| yes| Currency code, e.g. "NGN"
sizeOrDimensions| string| yes| Size or dimensions depending on the product
description| string| yes| Product description
material| string| no| Material where applicable
deletedAt| timestamp| no| Nullable. Used for soft deletion because old orders may still reference the product
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

4. Product Colour
   Stores the available colours for a product and the stock quantity for each colour. A colour is an option under a product, not a separate product.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
productId| UUID| yes| Foreign key to Product. Together with colour, must be unique
colour| string| yes| Available colour for the product
stockQuantity| integer| yes| Current stock for this colour. Cannot be below 0
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 


5. Cart
   Represents a buyer's shopping cart.
   Remaining Entity Schema
Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
userId| UUID| yes| Foreign key to User. Must be unique to enforce one active cart per buyer
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 


6. Cart Item
   Represents a specific product, selected colour, and quantity added to a cart.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
cartId| UUID| yes| Foreign key to Cart
productColourId| UUID| yes| Foreign key to Product Colour
quantity| integer| yes| Must be greater than 0
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

Constraint: "cartId + productColourId" must be unique so the same colour cannot appear twice in one cart.

7. Order
   Represents a purchase made by a buyer. It stores information such as the buyer, total amount, payment status, order status, and delivery address.
Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
buyerId| UUID| yes| Foreign key to User
total| integer| yes| Whole number in kobo. Must be greater than 0
currency| string| yes| Currency code, e.g. "NGN"
status| enum| yes| Fixed order status values
deliveryAddress| string| yes| Copy of the buyer's delivery address at order time, so it stays correct if the buyer changes their address later
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

8. Order Item
   Represents each product and selected colour included in an order.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
orderId| UUID| yes| Foreign key to Order
sellerId| UUID| yes| Foreign key to Seller. Duplicates the seller reachable through Product Colour so a seller can access their own order items quickly, even if the product is later removed
productColourId| UUID| yes| Foreign key to Product Colour. ON DELETE RESTRICT because a colour that appears in an order can never be hard-deleted
productName| string| yes| Copy of the product name at purchase time
colourName| string| yes| Copy of the colour name at purchase time
unitPrice| integer| yes| Product price in kobo at purchase time. Must be 0 or more
quantity| integer| yes| Quantity purchased. Must be greater than 0
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

Note: "productName", "colourName", and "unitPrice" are intentionally copied onto the Order Item. This preserves the details of what the buyer purchased even if the product name, colour name, or price changes later.

9. Payment
   Stores payment information related to an order, such as amount, payment status, and payment reference.
   Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
orderId| UUID| yes| Foreign key to Order
amount| integer| yes| Whole number in kobo. Must be greater than 0
currency| string| yes| Currency code, e.g. "NGN"
status| enum| yes| Fixed payment status values
paymentReference| string| yes| Unique payment reference
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 


10. Review
    Stores a buyer's review and rating for a product after the order has been delivered.
    Field| Type| Required?| Notes
id| UUID| yes| generated, not sequential
orderItemId| UUID| yes| Foreign key to Order Item. Must be unique
rating| integer| yes| Must be between 1 and 5
comment| string| no| Buyer's review comment
createdAt| timestamp| yes| 
updatedAt| timestamp| yes| 

Constraint: "orderItemId" must be unique so each purchased order item can have only one review.
   

## Relationships
The entities in the Fashion Marketplace are connected as follows:
- User → Seller: 1:1. A user can have one seller profile.
- Seller → Product: 1:N. One seller can list many products.
- Product → Product Colour: 1:N. One product can have multiple colours.
- User → Cart: 1:1. One buyer has one active cart.
- Cart → Cart Item: 1:N. One cart can contain many items.
- Product Colour → Cart Item: 1:N. A product colour can appear in many cart items.
- User → Order: 1:N. One buyer can place many orders.
- Order → Order Item: 1:N. One order can contain many items.
- Seller → Order Item: 1:N. One seller can have many order items. Each order item belongs to one seller, so a seller only sees their own items.
- Product Colour → Order Item: 1:N. A product colour can appear in many order items.
- Order → Payment: 1:N. One order can have multiple payment attempts, such as when a previous payment fails and the buyer retries.
- Order Item → Review: 1:0..1. An order item can have zero or one review. A review must belong to an order item.
- User → Review: via Order Item. A buyer is connected to a review through Review → Order Item → Order → User.

## Hard Questions

## API Contracts

## Schema Proof