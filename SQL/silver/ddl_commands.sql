/*
===============================================================================
Silver Layer - Table Creation
===============================================================================

Purpose:
    Creates the Silver layer tables for the Brazilian E-Commerce Data Warehouse.

    The Silver layer contains cleaned, standardized, and type-corrected data
    derived from the Bronze layer while preserving the business relationships
    present in the source data.

Key transformations applied during Silver loading include:
    - Data type standardization
    - Text trimming and formatting
    - Date and datetime conversion
    - Numeric precision standardization
    - Handling of NULL values
    - Duplicate/redundant record handling where required
    - Standardization of column naming

All Silver tables are recreated to provide a clean and consistent structure
for downstream Gold-layer dimensional modeling and analytics.

===============================================================================
*/


/*-----------------------------------------------------------------------------
    Customer Information
    Stores customer-level information from the Olist customer dataset.
    customer_id is retained to preserve the relationship with orders, while
    customer_unique_id represents the actual unique customer identity.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info
(
    customer_id         VARCHAR(32),
    customer_unique_id  VARCHAR(32),
    customer_zip_code   VARCHAR(5),
    customer_city       VARCHAR(100),
    customer_state      VARCHAR(20)
);
GO


/*-----------------------------------------------------------------------------
    Customer Reviews
    Stores cleaned customer review information associated with orders.
    Review creation date is stored as DATE because the source contains no
    meaningful time component, while review answer date retains DATETIME
    precision because its time component is meaningful.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.crm_cust_reviews', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_reviews;
GO

CREATE TABLE silver.crm_cust_reviews
(
    review_id             VARCHAR(50),
    order_id              VARCHAR(50),
    review_score          INT,
    review_title          VARCHAR(100),
    review_message        VARCHAR(1000),
    review_creation_date  DATE,
    review_answer_date    DATETIME
);
GO


/*-----------------------------------------------------------------------------
    Order Payments
    Stores standardized payment information for each order.
    An order can contain multiple payment records, therefore order_id is not
    treated as a unique identifier in this table.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.finance_ord_payments', 'U') IS NOT NULL
    DROP TABLE silver.finance_ord_payments;
GO

CREATE TABLE silver.finance_ord_payments
(
    order_id              VARCHAR(50),
    payment_sequential     INT,
    payment_type           VARCHAR(32),
    payment_installments   INT,
    payment_value          DECIMAL(10,2)
);
GO


/*-----------------------------------------------------------------------------
    Seller Information
    Stores cleaned seller details including location information.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.prd_seller_details', 'U') IS NOT NULL
    DROP TABLE silver.prd_seller_details;
GO

CREATE TABLE silver.prd_seller_details
(
    seller_id              VARCHAR(50),
    seller_zip_code_prefix  VARCHAR(10),
    seller_city             VARCHAR(100),
    seller_state            VARCHAR(20)
);
GO


/*-----------------------------------------------------------------------------
    Product Information
    Stores standardized product attributes including category, dimensions,
    weight, description length, name length, and number of product photos.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.prd_item_details', 'U') IS NOT NULL
    DROP TABLE silver.prd_item_details;
GO

CREATE TABLE silver.prd_item_details
(
    product_id                VARCHAR(50),
    product_category_name     VARCHAR(100),
    product_name_length       INT,
    product_description_length INT,
    product_photos_qty        INT,
    product_weight_g          INT,
    product_length_cm         INT,
    product_height_cm         INT,
    product_width_cm          INT
);
GO


/*-----------------------------------------------------------------------------
    Product Category Translations
    Stores the mapping between the original Portuguese product category names
    and their English translations.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.prd_translations', 'U') IS NOT NULL
    DROP TABLE silver.prd_translations;
GO

CREATE TABLE silver.prd_translations
(
    product_category_name          VARCHAR(100),
    product_category_name_english  VARCHAR(100)
);
GO


/*-----------------------------------------------------------------------------
    Geolocation Reference
    Stores standardized geolocation information used to enrich customer and
    seller location data.
    
    Latitude and longitude are retained as VARCHAR in this layer because the
    source data required additional cleansing/validation before numeric
    conversion.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.reference_geolocation', 'U') IS NOT NULL
    DROP TABLE silver.reference_geolocation;
GO

CREATE TABLE silver.reference_geolocation
(
    geolocation_zip_code_prefix  VARCHAR(10),
    geolocation_lat               VARCHAR(50),
    geolocation_lng               VARCHAR(50),
    geolocation_city              VARCHAR(100),
    geolocation_state             VARCHAR(20)
);
GO


/*-----------------------------------------------------------------------------
    Order Items
    Stores item-level details for orders, including products, sellers,
    prices, freight values, and shipping deadlines.
    
    An order can contain multiple items, therefore order_id is not unique.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.sales_ord_items', 'U') IS NOT NULL
    DROP TABLE silver.sales_ord_items;
GO

CREATE TABLE silver.sales_ord_items
(
    order_id              VARCHAR(50),
    order_item_id         INT,
    product_id            VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   DATETIME,
    price                 DECIMAL(10,2),
    freight_value         DECIMAL(10,2)
);
GO


/*-----------------------------------------------------------------------------
    Order Details
    Stores standardized order lifecycle information including customer,
    order status, purchase, approval, delivery, and estimated delivery dates.

    DATETIME is used for timestamps containing meaningful time information.
    The estimated delivery date is stored as DATE because the source provides
    no meaningful time component for this field.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('silver.sales_ord_details', 'U') IS NOT NULL
    DROP TABLE silver.sales_ord_details;
GO

CREATE TABLE silver.sales_ord_details
(
    order_id                         VARCHAR(32),
    customer_id                      VARCHAR(32),
    order_status                     VARCHAR(50),
    order_purchase_timestamp         DATETIME,
    order_approved_at                DATETIME,
    order_delivered_carrier_date     DATETIME,
    order_delivered_customer_date    DATETIME,
    order_estimated_delivery_date    DATE
);
GO
