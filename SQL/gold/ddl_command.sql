/* ============================================================
   GOLD LAYER
   ============================================================
   Purpose:
   - Create business-ready analytical views from the Silver layer.
   - Generate surrogate keys for dimensions and fact records.
   - Apply business rules and enrich data for analytics.
   - Maintain a clearly defined grain for each Gold object.
   ============================================================ */


/* ============================================================
   DIM_CUSTOMER
   ============================================================
   Grain:
   - One row per unique customer.

   Business Logic:
   - customer_unique_id represents the actual unique customer.
   - Multiple customer_id records can exist for the same
     customer_unique_id.
   - The record with the highest customer_id is retained as the
     representative customer record.
   - Customer location attributes are retained from the selected
     record.
   - A surrogate customer_key is generated for the Gold layer.
   ============================================================ */

IF OBJECT_ID('gold.dim_customer', 'V') IS NOT NULL 
    DROP VIEW gold.dim_customer; 
GO 
 
CREATE VIEW gold.dim_customer AS 
SELECT  
    ROW_NUMBER() OVER(ORDER BY customer_unique_id) AS customer_key, 
    customer_unique_id, 
    customer_zip_code, 
    customer_city, 
    customer_state 
FROM 
( 
    SELECT 
        ROW_NUMBER() OVER(
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
   ============================================================
   Grain:
   - One row per seller.

   Business Logic:
   - Seller information is enriched with latitude and longitude
     from the geolocation reference data.
   - A ZIP-code prefix can have multiple latitude/longitude
     combinations.
   - One deterministic geolocation record is selected for each
     ZIP-code prefix to prevent duplicate seller records.
   - LEFT JOIN ensures sellers without matching geolocation data
     are still retained.
   - A surrogate seller_key is generated.
   ============================================================ */

IF OBJECT_ID('gold.dim_seller', 'V') IS NOT NULL 
    DROP VIEW gold.dim_seller; 
GO 
 
CREATE VIEW gold.dim_seller AS 
SELECT  
    ROW_NUMBER() OVER(ORDER BY s.seller_id) AS seller_key, 
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
            ROW_NUMBER() OVER(
                PARTITION BY geolocation_zip_code_prefix 
                ORDER BY geolocation_lat, geolocation_lng
            ) AS rn, 
            * 
        FROM silver.reference_geolocation 
    )t 
    WHERE rn = 1 
) AS g 
ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;  
GO 


/* ============================================================
   DIM_PRODUCTS
   ============================================================
   Grain:
   - One row per product.

   Business Logic:
   - Product details are enriched with English product category
     names from the translation table.
   - LEFT JOIN ensures products without a matching translation
     are retained.
   - Missing category translations are represented as 'n/a'.
   - A surrogate product_key is generated.
   ============================================================ */

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL 
    DROP VIEW gold.dim_products; 
GO 
 
CREATE VIEW gold.dim_products AS 
SELECT  
    ROW_NUMBER() OVER(ORDER BY product_id) AS product_key, 
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
   ============================================================
   Grain:
   - One row per order.

   Business Logic:
   - sales_ord_details provides the base order-level information.
   - Order-item data is aggregated to order level before joining.
   - Payment data is aggregated to order level before joining.
   - This prevents row multiplication caused by multiple items
     and multiple payment records for the same order.
   - Shipping limit date is represented using the earliest
     shipping limit date for the order.
   - Total items, price and freight value are calculated per order.
   - Payment count, installments and payment value are calculated
     per order.
   - Review information is joined from the Silver review table,
     which has already been reduced to one review per order.
   - Missing item-level measures are represented as 0.
   - Missing review IDs are represented as 'n/a' and missing
     review scores as 0.
   - customer_id is mapped to customer_unique_id through the
     Silver customer table to support customer-level analysis.
   - A surrogate order_key is generated.
   ============================================================ */

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL 
    DROP VIEW gold.fact_sales; 
GO 
 
CREATE VIEW gold.fact_sales AS 
SELECT  
    ROW_NUMBER() OVER(ORDER BY od.order_id) AS order_key, 
    od.order_id, 
    c.customer_unique_id, 
    od.order_status, 
    od.order_purchase_timestamp, 
    od.order_approved_at, 
    ot.shipping_limit_date, 
    od.order_delivered_carrier_date, 
    od.order_delivered_customer_date, 
    od.order_estimated_delivery_date, 
 
    ISNULL(ot.total_items, 0) AS total_items, 
    ISNULL(ot.total_price, 0) AS total_price, 
    ISNULL(ot.total_freight_value, 0) AS total_freight_value, 
 
    f.payment_count, 
    f.total_payment_installments, 
    f.total_payment_value, 
 
    ISNULL(r.review_id, 'n/a') AS review_id, 
    ISNULL(r.review_score, 0) AS review_score, 
    r.review_creation_date, 
    r.review_answer_date 
     
FROM silver.sales_ord_details AS od 

LEFT JOIN 
( 
    /* Aggregate order-item data to one row per order */
    SELECT  
        order_id, 
        MIN(shipping_limit_date) AS shipping_limit_date, 
        COUNT(*) AS total_items, 
        SUM(price) AS total_price, 
        SUM(freight_value) AS total_freight_value 
    FROM silver.sales_ord_items 
    GROUP BY order_id 
) AS ot 
ON od.order_id = ot.order_id 

LEFT JOIN  
( 
    /* Aggregate payment data to one row per order */
    SELECT 
        order_id, 
        COUNT(*) AS payment_count, 
        SUM(payment_installments) AS total_payment_installments, 
        SUM(payment_value) AS total_payment_value 
    FROM silver.finance_ord_payments 
    GROUP BY order_id 
) AS f 
ON od.order_id = f.order_id 

/* Join the latest retained review for each order */
LEFT JOIN silver.crm_cust_reviews AS r 
    ON od.order_id = r.order_id 

/* Map order customer_id to the actual unique customer */
LEFT JOIN silver.crm_cust_info AS c 
    ON c.customer_id = od.customer_id; 
GO
