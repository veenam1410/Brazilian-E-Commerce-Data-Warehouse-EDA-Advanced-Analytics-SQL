/*
===============================================================================
Procedure: bronze.load_bronze
===============================================================================

Purpose:
    Load source data from the Olist Brazilian E-Commerce dataset into the
    Bronze layer of the Data Warehouse.

Bronze Layer Approach:
    - Acts as the initial ingestion layer of the data warehouse.
    - Loads data from source CSV files into Bronze tables.
    - Existing Bronze data is truncated before each load to support a full
      refresh.
    - Minimal transformation is performed during ingestion.
    - Source data is retained as close to its original representation as
      possible.
    - Special source-data formatting issues are handled separately using
      dedicated ingestion scripts.

Tables Loaded:
    1. bronze.crm_cust_info
    2. bronze.crm_cust_reviews
    3. bronze.finance_ord_payments
    4. bronze.prd_item_details
    5. bronze.prd_translations
    6. bronze.sales_ord_details
    7. bronze.sales_ord_items

Special Handling:
    - Customer reviews use FORMAT = 'CSV' and FIELDQUOTE = '"'
      because review text fields can contain commas and quoted values.
    - Seller and geolocation data require custom raw staging and parsing
      because of source-data formatting inconsistencies. These are handled
      in separate SQL scripts.

Logging:
    - Records start and end time for each table load.
    - Calculates the loading duration for each table.
    - Records the total Bronze-layer loading duration.
    - TRY/CATCH is used to capture and report loading errors.

===============================================================================
*/


-- ============================================================================
-- Create or modify the Bronze loading procedure
-- ============================================================================

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    -- Variables used to track individual table and overall batch load times
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;


    BEGIN TRY

        -- ====================================================================
        -- Start Bronze Layer Load
        -- ====================================================================

        SET @batch_start_time = GETDATE();

        PRINT 'LOADING BRONZE LAYER';


        -- ====================================================================
        -- 1. Load Customer Information
        -- ====================================================================

        PRINT 'Loading bronze.crm_cust_info Table';

        SET @start_time = GETDATE();

        -- Clear existing data before performing a full reload
        TRUNCATE TABLE bronze.crm_cust_info;

        -- Load customer data from the source CSV
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_crm\olist_customers_dataset.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 2. Load Customer Reviews
        -- ====================================================================

        PRINT 'Loading bronze.crm_cust_reviews Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_cust_reviews;

        -- CSV format is explicitly specified because review fields may contain
        -- commas and quoted text.
        BULK INSERT bronze.crm_cust_reviews
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_crm\olist_order_reviews_dataset.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDQUOTE = '"',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 3. Load Order Payments
        -- ====================================================================

        PRINT 'Loading bronze.finance_ord_payments Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.finance_ord_payments;

        BULK INSERT bronze.finance_ord_payments
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_finance\olist_order_payments_dataset.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 4. Load Product Information
        -- ====================================================================

        PRINT 'Loading bronze.prd_item_details Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.prd_item_details;

        BULK INSERT bronze.prd_item_details
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_products\olist_products_dataset.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 5. Load Product Category Translations
        -- ====================================================================

        PRINT 'Loading bronze.prd_translations Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.prd_translations;

        BULK INSERT bronze.prd_translations
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_products\product_category_name_translation.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 6. Load Order Details
        -- ====================================================================

        PRINT 'Loading bronze.sales_ord_details Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.sales_ord_details;

        BULK INSERT bronze.sales_ord_details
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_sales\olist_orders_dataset.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- 7. Load Order Item Details
        -- ====================================================================

        PRINT 'Loading bronze.sales_ord_items Table';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.sales_ord_items;

        BULK INSERT bronze.sales_ord_items
        FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_sales\olist_order_items_dataset.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        -- ====================================================================
        -- Bronze Layer Load Completed
        -- ====================================================================

        SET @batch_end_time = GETDATE();

        PRINT 'Load Completed';

        PRINT '>> Load Bronze Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
            + ' seconds';


    END TRY


    -- ========================================================================
    -- Error Handling
    -- ========================================================================

    BEGIN CATCH

        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';

        PRINT 'Error Message: '
            + ERROR_MESSAGE();

        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR);

    END CATCH

END;
GO


-- ============================================================================
-- Execute Bronze Layer Loading Procedure
-- ============================================================================

EXEC bronze.load_bronze;
GO
