/*
===============================================================================
                    SILVER LAYER - DATA QUALITY TESTS
===============================================================================

Purpose:
    Validate the quality of Bronze-layer data before transformation and verify
    that the Silver-layer transformations have correctly cleaned, standardized,
    and deduplicated the data.

Validation areas:
    - Duplicate records
    - NULL values
    - Whitespace and formatting issues
    - Invalid data types
    - Source-specific data quality issues
    - Transformation validation
    - Post-load Silver data quality

===============================================================================
*/


/*
===============================================================================
1. CUSTOMER INFORMATION - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for duplicate customer_id values
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_cust_info
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check for NULL customer_id
SELECT *
FROM bronze.crm_cust_info
WHERE customer_id IS NULL;


-- Check for NULL customer_unique_id
SELECT *
FROM bronze.crm_cust_info
WHERE customer_unique_id IS NULL;


-- Check for NULL customer_zip_code
SELECT *
FROM bronze.crm_cust_info
WHERE customer_zip_code IS NULL;


-- Check for NULL customer_city
SELECT *
FROM bronze.crm_cust_info
WHERE customer_city IS NULL;


-- Check for NULL customer_state
SELECT *
FROM bronze.crm_cust_info
WHERE customer_state IS NULL;


-- Check for leading/trailing whitespace in customer_id
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_info
WHERE LEN(customer_id) <> LEN(TRIM(customer_id));


-- Check for leading/trailing whitespace in customer_unique_id
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_info
WHERE LEN(customer_unique_id) <> LEN(TRIM(customer_unique_id));


-- Check for leading/trailing whitespace in customer_zip_code
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_info
WHERE LEN(customer_zip_code) <> LEN(TRIM(customer_zip_code));


-- Check for leading/trailing whitespace in customer_city
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_info
WHERE LEN(customer_city) <> LEN(TRIM(customer_city));


-- Check for leading/trailing whitespace in customer_state
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_info
WHERE LEN(customer_state) <> LEN(TRIM(customer_state));


/*
===============================================================================
2. CUSTOMER REVIEWS - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for duplicate review_id values
SELECT
    review_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_cust_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;


-- Inspect records for a duplicated review_id
SELECT *
FROM bronze.crm_cust_reviews
WHERE review_id = '4219a80ab469e3fc9901437b73da3f75';


-- Check for orders having multiple reviews
SELECT
    order_id,
    COUNT(*) AS review_count
FROM bronze.crm_cust_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


-- Inspect an order containing multiple reviews
SELECT *
FROM bronze.crm_cust_reviews
WHERE order_id = 'ab71e5dff0ed652f1559e1860391bd22';


-- Check for exact duplicate review records
SELECT
    review_id,
    order_id,
    review_score,
    review_title,
    review_message,
    review_creation_date,
    review_answer_date,
    COUNT(*) AS occurrence_count
FROM bronze.crm_cust_reviews
GROUP BY
    review_id,
    order_id,
    review_score,
    review_title,
    review_message,
    review_creation_date,
    review_answer_date
HAVING COUNT(*) > 1;


-- Check for whitespace in review_id
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_reviews
WHERE LEN(review_id) <> LEN(TRIM(review_id));


-- Check for whitespace in order_id
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_reviews
WHERE LEN(order_id) <> LEN(TRIM(order_id));


-- Check for whitespace in review_title
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_reviews
WHERE LEN(review_title) <> LEN(TRIM(review_title));


-- Check for whitespace in review_message
SELECT COUNT(*) AS whitespace_count
FROM bronze.crm_cust_reviews
WHERE LEN(review_message) <> LEN(TRIM(review_message));


-- Check for invalid review creation dates
SELECT *
FROM bronze.crm_cust_reviews
WHERE TRY_CONVERT(DATE, review_creation_date) IS NULL
  AND review_creation_date IS NOT NULL;


-- Check for invalid review answer dates
SELECT *
FROM bronze.crm_cust_reviews
WHERE TRY_CONVERT(DATETIME, review_answer_date) IS NULL
  AND review_answer_date IS NOT NULL;


/*
===============================================================================
3. ORDER PAYMENTS - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for multiple payment records per order
SELECT
    order_id,
    COUNT(*) AS payment_count
FROM bronze.finance_ord_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;


-- Inspect an order containing multiple payment records
SELECT *
FROM bronze.finance_ord_payments
WHERE order_id = 'dc952dba5b4ae9cc2ea0eb4757f0cdd0';


-- Check payment type values
SELECT DISTINCT
    payment_type
FROM bronze.finance_ord_payments
ORDER BY payment_type;


-- Check for whitespace in payment_type
SELECT COUNT(*) AS whitespace_count
FROM bronze.finance_ord_payments
WHERE LEN(payment_type) <> LEN(TRIM(payment_type));


-- Check for quotation marks or whitespace in order_id
SELECT
    order_id
FROM bronze.finance_ord_payments
WHERE order_id LIKE '%"%'
   OR LEN(order_id) <> LEN(TRIM(order_id));


-- Verify cleaned order_id
SELECT
    TRIM(REPLACE(order_id, '"', '')) AS cleaned_order_id
FROM bronze.finance_ord_payments;


/*
===============================================================================
4. PRODUCT INFORMATION - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for duplicate or NULL product IDs
SELECT
    product_id,
    COUNT(*) AS occurrence_count
FROM bronze.prd_item_details
GROUP BY product_id
HAVING COUNT(*) > 1
    OR product_id IS NULL;


-- Check product category values
SELECT DISTINCT
    product_category_name
FROM bronze.prd_item_details
ORDER BY product_category_name;


-- Check for NULL product category
SELECT *
FROM bronze.prd_item_details
WHERE product_category_name IS NULL;


-- Check NULL values in product attributes
SELECT *
FROM bronze.prd_item_details
WHERE product_name_length IS NULL
   OR product_description_length IS NULL
   OR product_photos_qty IS NULL
   OR product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;


-- Check for negative values in numeric product attributes
SELECT *
FROM bronze.prd_item_details
WHERE product_name_length < 0
   OR product_description_length < 0
   OR product_photos_qty < 0
   OR product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;


/*
===============================================================================
5. SELLER INFORMATION - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM bronze.prd_seller_details
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- Check for NULL seller IDs
SELECT *
FROM bronze.prd_seller_details
WHERE seller_id IS NULL;


-- Check for quotation marks in seller_id
SELECT *
FROM bronze.prd_seller_details
WHERE seller_id LIKE '%"%';


-- Check for whitespace in seller ZIP code
SELECT COUNT(*) AS whitespace_count
FROM bronze.prd_seller_details
WHERE LEN(seller_zip_code_prefix)
      <> LEN(TRIM(seller_zip_code_prefix));


-- Check for whitespace in seller city
SELECT COUNT(*) AS whitespace_count
FROM bronze.prd_seller_details
WHERE LEN(seller_city)
      <> LEN(TRIM(seller_city));


-- Check for whitespace in seller state
SELECT COUNT(*) AS whitespace_count
FROM bronze.prd_seller_details
WHERE LEN(seller_state)
      <> LEN(TRIM(seller_state));


/*
===============================================================================
6. PRODUCT CATEGORY TRANSLATIONS - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for NULL category names
SELECT *
FROM bronze.prd_translations
WHERE product_category_name IS NULL;


-- Check for NULL English translations
SELECT *
FROM bronze.prd_translations
WHERE product_category_name_english IS NULL;


-- Check for leading/trailing whitespace
SELECT *
FROM bronze.prd_translations
WHERE LEN(product_category_name)
      <> LEN(TRIM(product_category_name))
   OR LEN(product_category_name_english)
      <> LEN(TRIM(product_category_name_english));


/*
===============================================================================
7. GEOLOCATION - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for exact duplicate geolocation records
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS duplicate_count
FROM bronze.reference_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;


-- Inspect geolocation records for a duplicated ZIP prefix
SELECT *
FROM bronze.reference_geolocation
WHERE geolocation_zip_code_prefix = '"68903'
ORDER BY
    geolocation_lat,
    geolocation_lng;


-- Check for NULL geolocation attributes
SELECT *
FROM bronze.reference_geolocation
WHERE geolocation_zip_code_prefix IS NULL
   OR geolocation_lat IS NULL
   OR geolocation_lng IS NULL
   OR geolocation_city IS NULL
   OR geolocation_state IS NULL;


/*
===============================================================================
8. ORDER ITEMS - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for exact duplicate order-item records
SELECT
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    COUNT(*) AS duplicate_count
FROM bronze.sales_ord_items
GROUP BY
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
HAVING COUNT(*) > 1;


-- Inspect an order containing duplicate order-item records
SELECT *
FROM bronze.sales_ord_items
WHERE order_id = '"6df3204d235cde9188ca8235366848b7';


-- Check for quotation marks in identifiers
SELECT *
FROM bronze.sales_ord_items
WHERE order_id LIKE '%"%'
   OR product_id LIKE '%"%'
   OR seller_id LIKE '%"%';


-- Check for invalid shipping dates
SELECT *
FROM bronze.sales_ord_items
WHERE TRY_CONVERT(DATETIME, shipping_limit_date) IS NULL
  AND shipping_limit_date IS NOT NULL;


/*
===============================================================================
9. ORDER DETAILS - BRONZE QUALITY CHECKS
===============================================================================
*/


-- Check for duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM bronze.sales_ord_details
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Check for NULL order IDs
SELECT *
FROM bronze.sales_ord_details
WHERE order_id IS NULL;


-- Check order status values
SELECT DISTINCT
    order_status
FROM bronze.sales_ord_details
ORDER BY order_status;


-- Check for NULL customer IDs
SELECT *
FROM bronze.sales_ord_details
WHERE customer_id IS NULL;


-- Check for invalid order timestamps
SELECT *
FROM bronze.sales_ord_details
WHERE TRY_CONVERT(DATETIME, order_purchase_timestamp, 105) IS NULL
  AND order_purchase_timestamp IS NOT NULL;

SELECT *
FROM bronze.sales_ord_details
WHERE TRY_CONVERT(DATETIME, order_approved_at, 105) IS NULL
  AND order_approved_at IS NOT NULL;

SELECT *
FROM bronze.sales_ord_details
WHERE TRY_CONVERT(DATETIME, order_delivered_carrier_date, 105) IS NULL
  AND order_delivered_carrier_date IS NOT NULL;

SELECT *
FROM bronze.sales_ord_details
WHERE TRY_CONVERT(DATETIME, order_delivered_customer_date, 105) IS NULL
  AND order_delivered_customer_date IS NOT NULL;


-- Check estimated delivery date conversion
SELECT
    order_estimated_delivery_date,
    LEFT(order_estimated_delivery_date, 10) AS date_part,
    TRY_CONVERT(
        DATE,
        LEFT(order_estimated_delivery_date, 10),
        105
    ) AS converted_date
FROM bronze.sales_ord_details
WHERE order_estimated_delivery_date IS NOT NULL;


/*
===============================================================================
                    SILVER LAYER - POST LOAD VALIDATION
===============================================================================
*/


/*
-----------------------------------------------------------------------------
10. CUSTOMER - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that customer_id is unique
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Verify required customer IDs are not NULL
SELECT *
FROM silver.crm_cust_info
WHERE customer_id IS NULL
   OR customer_unique_id IS NULL;


/*
-----------------------------------------------------------------------------
11. CUSTOMER REVIEWS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that only one review remains per order
SELECT
    order_id,
    COUNT(*) AS review_count
FROM silver.crm_cust_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Verify that review_id + order_id contains no exact duplicates
SELECT
    review_id,
    order_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_reviews
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;


-- Verify that NULL review text has been replaced
SELECT *
FROM silver.crm_cust_reviews
WHERE review_title IS NULL
   OR review_message IS NULL;


/*
-----------------------------------------------------------------------------
12. PAYMENTS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that payment records are retained for multiple-payment orders
SELECT
    order_id,
    COUNT(*) AS payment_count
FROM silver.finance_ord_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;


-- Verify that cleaned order IDs contain no quotation marks
SELECT *
FROM silver.finance_ord_payments
WHERE order_id LIKE '%"%';


/*
-----------------------------------------------------------------------------
13. PRODUCTS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that product IDs are not NULL
SELECT *
FROM silver.prd_item_details
WHERE product_id IS NULL;


-- Verify that product numeric attributes contain no NULLs
SELECT *
FROM silver.prd_item_details
WHERE product_name_length IS NULL
   OR product_description_length IS NULL
   OR product_photos_qty IS NULL
   OR product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;


/*
-----------------------------------------------------------------------------
14. SELLERS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that seller IDs contain no quotation marks
SELECT *
FROM silver.prd_seller_details
WHERE seller_id LIKE '%"%'
   OR seller_zip_code_prefix LIKE '%"%';


-- Verify that seller IDs are unique
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM silver.prd_seller_details
GROUP BY seller_id
HAVING COUNT(*) > 1;


/*
-----------------------------------------------------------------------------
15. GEOLOCATION - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that exact duplicate geolocation records were removed
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS duplicate_count
FROM silver.reference_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;


-- Verify that ZIP code quotation marks were removed
SELECT *
FROM silver.reference_geolocation
WHERE geolocation_zip_code_prefix LIKE '%"%';


/*
-----------------------------------------------------------------------------
16. ORDER ITEMS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that exact duplicate order-item records were removed
SELECT
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    COUNT(*) AS duplicate_count
FROM silver.sales_ord_items
GROUP BY
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
HAVING COUNT(*) > 1;


-- Verify that IDs contain no quotation marks
SELECT *
FROM silver.sales_ord_items
WHERE order_id LIKE '%"%'
   OR product_id LIKE '%"%'
   OR seller_id LIKE '%"%';


/*
-----------------------------------------------------------------------------
17. ORDER DETAILS - SILVER VALIDATION
-----------------------------------------------------------------------------
*/


-- Verify that order_id is unique
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM silver.sales_ord_details
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Verify that required IDs are not NULL
SELECT *
FROM silver.sales_ord_details
WHERE order_id IS NULL
   OR customer_id IS NULL;


-- Verify standardized order status values
SELECT DISTINCT
    order_status
FROM silver.sales_ord_details
ORDER BY order_status;


-- Verify that estimated delivery date is stored correctly
SELECT
    order_estimated_delivery_date
FROM silver.sales_ord_details
WHERE order_estimated_delivery_date IS NOT NULL
  AND TRY_CONVERT(DATE, order_estimated_delivery_date) IS NULL;


/*
===============================================================================
                         END OF SILVER TESTS
===============================================================================

Expected outcome:
    Queries identifying a successfully resolved data-quality issue should
    return zero rows after the Silver transformation.

    Legitimate one-to-many relationships, such as:
        - One order -> multiple payments
        - One order -> multiple order items

    should NOT be treated as duplicate data.

===============================================================================
*/
