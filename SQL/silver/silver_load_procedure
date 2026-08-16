/*
===============================================================================
                    SILVER LAYER - DATA TRANSFORMATION
===============================================================================

Purpose:
    Clean, standardize, deduplicate, and transform data from the Bronze layer
    before loading it into the Silver layer.

Key transformations:
    - Preserve source identifiers for traceability and table relationships.
    - Remove unwanted quotation marks and whitespace.
    - Standardize text formatting and category names.
    - Handle NULL values where appropriate.
    - Convert columns to appropriate data types.
    - Remove exact duplicate records where identified.
    - Retain the latest review for orders having multiple reviews.
    - Preserve the precision of source geolocation coordinates.

===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'LOADING SILVER LAYER';
        PRINT '================================================';


        /*==============================================================
          1. CUSTOMER INFORMATION
        ==============================================================*/

        PRINT 'Loading silver.crm_cust_info Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info
        (
            customer_id,
            customer_unique_id,
            customer_zip_code,
            customer_city,
            customer_state
        )
        SELECT
            customer_id,
            customer_unique_id,
            customer_zip_code,

            UPPER(LEFT(customer_city, 1))
                + LOWER(SUBSTRING(customer_city, 2, LEN(customer_city)))
                AS customer_city,

            customer_state

        FROM bronze.crm_cust_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          2. CUSTOMER REVIEWS
        ==============================================================*/

        PRINT 'Loading silver.crm_cust_reviews Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.crm_cust_reviews;

        INSERT INTO silver.crm_cust_reviews
        (
            review_id,
            order_id,
            review_score,
            review_title,
            review_message,
            review_creation_date,
            review_answer_date
        )
        SELECT
            review_id,
            order_id,
            review_score,
            review_title,
            review_message,
            review_creation_date,
            review_answer_date

        FROM
        (
            SELECT
                review_id,
                order_id,
                review_score,

                ISNULL(TRIM(review_title), 'n/a') AS review_title,
                ISNULL(TRIM(review_message), 'n/a') AS review_message,

                CAST(review_creation_date AS DATE)
                    AS review_creation_date,

                CAST(review_answer_date AS DATETIME)
                    AS review_answer_date,

                ROW_NUMBER() OVER
                (
                    PARTITION BY order_id
                    ORDER BY
                        review_creation_date DESC,
                        review_answer_date DESC,
                        review_id DESC
                ) AS rn

            FROM bronze.crm_cust_reviews
        ) t

        WHERE rn = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          3. ORDER PAYMENTS
        ==============================================================*/

        PRINT 'Loading silver.finance_ord_payments Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.finance_ord_payments;

        INSERT INTO silver.finance_ord_payments
        (
            order_id,
            payment_sequential,
            payment_type,
            payment_installments,
            payment_value
        )
        SELECT
            TRIM(REPLACE(order_id, '"', '')) AS order_id,

            payment_sequential,

            REPLACE(
                UPPER(LEFT(payment_type, 1))
                + LOWER(SUBSTRING(payment_type, 2, LEN(payment_type))),
                '_',
                ' '
            ) AS payment_type,

            payment_installments,
            payment_value

        FROM bronze.finance_ord_payments;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          4. PRODUCT INFORMATION
        ==============================================================*/

        PRINT 'Loading silver.prd_item_details Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.prd_item_details;

        INSERT INTO silver.prd_item_details
        (
            product_id,
            product_category_name,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        )
        SELECT
            TRIM(REPLACE(product_id, '"', '')) AS product_id,

            ISNULL(
                REPLACE(
                    UPPER(LEFT(product_category_name, 1))
                    + LOWER(
                        SUBSTRING(
                            product_category_name,
                            2,
                            LEN(product_category_name)
                        )
                    ),
                    '_',
                    ' '
                ),
                'n/a'
            ) AS product_category_name,

            ISNULL(product_name_length, 0),
            ISNULL(product_description_length, 0),
            ISNULL(product_photos_qty, 0),
            ISNULL(product_weight_g, 0),
            ISNULL(product_length_cm, 0),
            ISNULL(product_height_cm, 0),
            ISNULL(product_width_cm, 0)

        FROM bronze.prd_item_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          5. SELLER INFORMATION
        ==============================================================*/

        PRINT 'Loading silver.prd_seller_details Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.prd_seller_details;

        INSERT INTO silver.prd_seller_details
        (
            seller_id,
            seller_zip_code_prefix,
            seller_city,
            seller_state
        )
        SELECT
            TRIM(REPLACE(seller_id, '"', '')) AS seller_id,

            TRIM(
                REPLACE(seller_zip_code_prefix, '"', '')
            ) AS seller_zip_code_prefix,

            UPPER(LEFT(seller_city, 1))
                + LOWER(
                    SUBSTRING(
                        seller_city,
                        2,
                        LEN(seller_city)
                    )
                ) AS seller_city,

            seller_state

        FROM bronze.prd_seller_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          6. PRODUCT CATEGORY TRANSLATIONS
        ==============================================================*/

        PRINT 'Loading silver.prd_translations Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.prd_translations;

        INSERT INTO silver.prd_translations
        (
            product_category_name,
            product_category_name_english
        )
        SELECT
            TRIM(
                REPLACE(
                    UPPER(LEFT(product_category_name, 1))
                    + LOWER(
                        SUBSTRING(
                            product_category_name,
                            2,
                            LEN(product_category_name)
                        )
                    ),
                    '_',
                    ' '
                )
            ) AS product_category_name,

            TRIM(
                REPLACE(
                    UPPER(LEFT(product_category_name_english, 1))
                    + LOWER(
                        SUBSTRING(
                            product_category_name_english,
                            2,
                            LEN(product_category_name_english)
                        )
                    ),
                    '_',
                    ' '
                )
            ) AS product_category_name_english

        FROM bronze.prd_translations;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          7. GEOLOCATION
        ==============================================================*/

        PRINT 'Loading silver.reference_geolocation Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.reference_geolocation;

        INSERT INTO silver.reference_geolocation
        (
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state
        )
        SELECT
            REPLACE(
                geolocation_zip_code_prefix,
                '"',
                ''
            ) AS geolocation_zip_code_prefix,

            geolocation_lat,
            geolocation_lng,

            UPPER(LEFT(geolocation_city, 1))
                + LOWER(
                    SUBSTRING(
                        geolocation_city,
                        2,
                        LEN(geolocation_city)
                    )
                ) AS geolocation_city,

            geolocation_state

        FROM
        (
            SELECT
                *,

                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        geolocation_zip_code_prefix,
                        geolocation_lat,
                        geolocation_lng,
                        geolocation_city,
                        geolocation_state

                    ORDER BY
                        geolocation_lat,
                        geolocation_lng
                ) AS rn

            FROM bronze.reference_geolocation
        ) t

        WHERE rn = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          8. ORDER ITEMS
        ==============================================================*/

        PRINT 'Loading silver.sales_ord_items Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.sales_ord_items;

        INSERT INTO silver.sales_ord_items
        (
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value
        )
        SELECT
            TRIM(REPLACE(order_id, '"', '')) AS order_id,

            order_item_id,

            TRIM(REPLACE(product_id, '"', '')) AS product_id,

            TRIM(REPLACE(seller_id, '"', '')) AS seller_id,

            CAST(shipping_limit_date AS DATETIME)
                AS shipping_limit_date,

            price,
            freight_value

        FROM
        (
            SELECT
                *,

                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        order_id,
                        product_id,
                        seller_id,
                        shipping_limit_date,
                        price,
                        freight_value

                    ORDER BY order_id
                ) AS rn

            FROM bronze.sales_ord_items
        ) t

        WHERE rn = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          9. ORDER DETAILS
        ==============================================================*/

        PRINT 'Loading silver.sales_ord_details Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.sales_ord_details;

        INSERT INTO silver.sales_ord_details
        (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
        SELECT
            order_id,
            customer_id,

            TRIM(
                UPPER(LEFT(order_status, 1))
                + LOWER(
                    SUBSTRING(
                        order_status,
                        2,
                        LEN(order_status)
                    )
                )
            ) AS order_status,

            TRY_CONVERT(
                DATETIME,
                order_purchase_timestamp,
                105
            ) AS order_purchase_timestamp,

            TRY_CONVERT(
                DATETIME,
                order_approved_at,
                105
            ) AS order_approved_at,

            TRY_CONVERT(
                DATETIME,
                order_delivered_carrier_date,
                105
            ) AS order_delivered_carrier_date,

            TRY_CONVERT(
                DATETIME,
                order_delivered_customer_date,
                105
            ) AS order_delivered_customer_date,

            TRY_CONVERT(
                DATE,
                LEFT(order_estimated_delivery_date, 10),
                105
            ) AS order_estimated_delivery_date

        FROM bronze.sales_ord_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*==============================================================
          COMPLETION
        ==============================================================*/

        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'SILVER LOAD COMPLETED';
        PRINT '>> Total Silver Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @batch_start_time,
                    @batch_end_time
                ) AS NVARCHAR
            )
            + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================';

    END CATCH

END;
GO


/*=============================================================================
    EXECUTE SILVER LOAD
=============================================================================*/

EXEC silver.load_silver;
GO
