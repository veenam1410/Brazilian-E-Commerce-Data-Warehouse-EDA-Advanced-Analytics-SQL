/* ============================================================
   GOLD LAYER - VERSION 2
   ============================================================

   This version of the Gold layer uses an ORDER-ITEM grain
   for the fact_sales table.

   Two Gold-layer versions are maintained to demonstrate
   different fact-table grains:

   Version 2:
   - fact_sales has one row per order item.
   - Each order item retains its product and seller information.
   - This allows direct relationships between the fact table
     and the customer, product, and seller dimensions.
   - Suitable for product-level, seller-level and order-item
     analysis.

   Version 2 was created because aggregating sales_order_items
   to the order level in Version 1 removes product_id and
   seller_id from the fact table, making the product and seller
   dimensions disconnected from the fact table.

   Therefore, Version 2 preserves the original order-item grain
   to maintain a proper Star Schema structure.

   FACT GRAIN:
   One row = One product item within an order.

   Dimensions:
   - dim_customer
   - dim_products
   - dim_seller
   ============================================================ */


/* ============================================================
   DIM_CUSTOMER
   Grain: One row per unique customer

   Multiple customer_ids can belong to the same
   customer_unique_id. The latest customer record is retained
   using customer_id DESC.
   ============================================================ */

IF OBJECT_ID('gold_v2.dim_customer', 'V') IS NOT NULL
    DROP VIEW gold_v2.dim_customer;
GO

CREATE VIEW gold_v2.dim_customer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_unique_id) AS customer_key,
    customer_unique_id,
    customer_zip_code,
    customer_city,
    customer_state
FROM
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY customer_id DESC
        ) AS rn,
        customer_unique_id,
        customer_zip_code,
        customer_city,
        customer_state
    FROM silver.crm_cust_info
)t
WHERE rn = 1;
GO


/* ============================================================
   DIM_SELLER
   Grain: One row per seller

   Seller location coordinates are associated using the seller's
   ZIP code. Since a ZIP code can have multiple latitude and
   longitude values, the first available coordinate pair is
   selected arbitrarily.
   ============================================================ */

IF OBJECT_ID('gold_v2.dim_seller', 'V') IS NOT NULL
    DROP VIEW gold_v2.dim_seller;
GO

CREATE VIEW gold_v2.dim_seller AS
SELECT
    ROW_NUMBER() OVER (ORDER BY s.seller_id) AS seller_key,
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.geolocation_lat,
    g.geolocation_lng
FROM silver.prd_seller_details AS s
LEFT JOIN
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng
    FROM
    (
        SELECT
            ROW_NUMBER() OVER (
                PARTITION BY geolocation_zip_code_prefix
                ORDER BY geolocation_lat, geolocation_lng
            ) AS rn,
            *
        FROM silver.reference_geolocation
    ) t
    WHERE rn = 1
) AS g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;
GO


/* ============================================================
   DIM_PRODUCTS
   Grain: One row per product

   Product category names are translated to English using the
   product translation table. Missing translations are assigned
   'n/a'.
   ============================================================ */

IF OBJECT_ID('gold_v2.dim_products', 'V') IS NOT NULL
    DROP VIEW gold_v2.dim_products;
GO

CREATE VIEW gold_v2.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
    p.product_id,
    ISNULL(t.product_category_name_english, 'n/a') AS product_category_name,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM silver.prd_item_details AS p
LEFT JOIN silver.prd_translations AS t
    ON p.product_category_name = t.product_category_name;
GO


/* ============================================================
   FACT_SALES
   Grain: One row per order item

   Unlike Version 1, the order items are NOT aggregated by
   order_id. This preserves product_id, seller_id and
   order_item_id for detailed sales analysis.

   Customer information is obtained through:
   sales_ord_items
        -> sales_ord_details
        -> crm_cust_info
        -> dim_customer

   Product information is obtained through:
   sales_ord_items
        -> dim_products

   Seller information is obtained through:
   sales_ord_items
        -> dim_seller
   ============================================================ */

IF OBJECT_ID('gold_v2.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold_v2.fact_sales;
GO

CREATE VIEW gold_v2.fact_sales AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY oi.order_id, oi.order_item_id
    ) AS sales_key,

    oi.order_id,
    oi.order_item_id,

    'CUST' + CAST(c.customer_key AS VARCHAR) AS customer_key,
    'PRD' + CAST(p.product_id AS VARCHAR) AS product_key,
    'S' + CAST(s.seller_id AS VARCHAR) AS seller_key,

    od.order_status,

    od.order_purchase_timestamp,
    od.order_approved_at,
    oi.shipping_limit_date,
    od.order_delivered_carrier_date,
    od.order_delivered_customer_date,
    od.order_estimated_delivery_date,

    oi.price,
    oi.freight_value

FROM silver.sales_ord_items AS oi

/* Retrieve order and customer information */
LEFT JOIN silver.sales_ord_details AS od
    ON oi.order_id = od.order_id

/* Map the order-level customer_id to customer_unique_id */
LEFT JOIN silver.crm_cust_info AS ci
    ON od.customer_id = ci.customer_id

/* Connect the order item to the customer dimension */
LEFT JOIN gold_v2.dim_customer AS c
    ON ci.customer_unique_id = c.customer_unique_id

/* Connect the order item to the product dimension */
LEFT JOIN gold_v2.dim_products AS p
    ON oi.product_id = p.product_id

/* Connect the order item to the seller dimension */
LEFT JOIN gold_v2.dim_seller AS s
    ON oi.seller_id = s.seller_id;
GO
