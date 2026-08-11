/*
===============================================================================
Special Bronze Layer Ingestion
Tables:
    1. bronze.prd_seller_details
    2. bronze.reference_geolocation
===============================================================================

DATA QUALITY ISSUES IDENTIFIED IN SOURCE FILES
-----------------------------------------------

1. Seller Dataset
   - Some seller_id and seller_zip_code_prefix values are enclosed in
     double quotes, while others are not.
   - Some seller_city values contain commas without being enclosed in
     double quotes.
   - Since comma is the standard CSV delimiter, these commas cause the
     seller_city value to be interpreted as multiple columns during a
     standard BULK INSERT.
   - This results in column shifting and truncation errors, particularly
     in the seller_state column.

2. Geolocation Dataset
   - Some source fields contain inconsistent double-quote formatting.
   - Some geolocation_city values contain commas.
   - Direct comma-based BULK INSERT can therefore incorrectly split the
     city value into multiple fields.
   - Latitude and longitude values have varying decimal precision and are
     therefore initially loaded as VARCHAR in the Bronze layer.

INGESTION APPROACH
------------------
To preserve the source data and avoid incorrect column splitting:

    CSV File
        ↓
    Raw Staging Table
        ↓
    Store complete CSV row as one value
        ↓
    Parse using SQL string functions
        ↓
    Remove inconsistent quotation marks
        ↓
    Load into Bronze tables

The raw staging approach preserves the complete source row before any
parsing or cleaning is performed.

===============================================================================
*/


/*
===============================================================================
1. SELLER DATA
===============================================================================
*/


-- ============================================================================
-- Create raw staging table for seller data
-- Each complete CSV row is stored as a single raw_data value.
-- ============================================================================

IF OBJECT_ID('bronze.seller_raw', 'U') IS NOT NULL
    DROP TABLE bronze.seller_raw;
GO

CREATE TABLE bronze.seller_raw
(
    raw_data VARCHAR(500)
);


-- ============================================================================
-- Load seller source data into raw staging
--
-- FIELDTERMINATOR = '0x0b' is intentionally used instead of ','.
-- This prevents commas inside seller_city from being interpreted as
-- column separators.
-- ============================================================================

BULK INSERT bronze.seller_raw
FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_products\olist_sellers_dataset.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '0x0b',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


-- ============================================================================
-- Parse and load seller data into the Bronze table
--
-- Source structure:
--     seller_id,
--     seller_zip_code_prefix,
--     seller_city,
--     seller_state
--
-- Parsing logic:
--     First value                  -> seller_id
--     Second value                 -> seller_zip_code_prefix
--     Last value                   -> seller_state
--     Everything between them     -> seller_city
--
-- REPLACE() removes inconsistent double quotes from source values.
-- ============================================================================

PRINT 'Loading bronze.prd_seller_details';

TRUNCATE TABLE bronze.prd_seller_details;

INSERT INTO bronze.prd_seller_details
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT

    -- Extract seller_id
        LEFT(
            raw_data,
            CHARINDEX(',', raw_data) - 1
        ) AS seller_id,


    -- Extract seller ZIP code
        SUBSTRING(
            raw_data,
            CHARINDEX(',', raw_data) + 1,
            CHARINDEX(',', raw_data, CHARINDEX(',', raw_data) + 1)
                - CHARINDEX(',', raw_data) - 1
        ) AS seller_zip_code_prefix,


    -- Extract seller city
    -- Everything after the second comma and before the final comma.
    -- This preserves commas that belong to the city value.
        SUBSTRING(
            raw_data,
            CHARINDEX(',', raw_data, CHARINDEX(',', raw_data) + 1) + 1,
            LEN(raw_data)
                - CHARINDEX(',', REVERSE(raw_data))
                - CHARINDEX(',', raw_data, CHARINDEX(',', raw_data) + 1)
        ) AS seller_city,


    -- Extract seller state
    -- The state is always the final value in the source row.
        RIGHT(
            raw_data,
            CHARINDEX(',', REVERSE(raw_data)) - 1
        ) AS seller_state

FROM bronze.seller_raw;



/*
===============================================================================
2. GEOLOCATION DATA
===============================================================================
*/


-- ============================================================================
-- Create raw staging table for geolocation data
-- ============================================================================

IF OBJECT_ID('bronze.geolocation_raw', 'U') IS NOT NULL
    DROP TABLE bronze.geolocation_raw;
GO

CREATE TABLE bronze.geolocation_raw
(
    raw_data VARCHAR(500)
);


-- ============================================================================
-- Load geolocation source data into raw staging
--
-- The complete CSV row is stored as one value to prevent commas contained
-- within city names from being interpreted as additional columns.
-- ============================================================================

BULK INSERT bronze.geolocation_raw
FROM 'C:\Users\VEENA M\OneDrive\Documents\DATA ANALYTICS Project\SQL Data Warehouse Project\datasets\source_reference\olist_geolocation_dataset.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '0x0b',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


-- ============================================================================
-- Parse and load geolocation data into the Bronze table
--
-- Source structure:
--     geolocation_zip_code_prefix,
--     geolocation_lat,
--     geolocation_lng,
--     geolocation_city,
--     geolocation_state
--
-- Parsing logic:
--     First value                  -> ZIP code
--     Second value                 -> Latitude
--     Third value                  -> Longitude
--     Last value                   -> State
--     Everything between third
--     and last value               -> City
--
-- Latitude and longitude are kept as VARCHAR in Bronze to preserve their
-- original source representation. They can be converted to numeric types
-- later during Silver-layer transformation.
-- ============================================================================

PRINT 'Loading bronze.reference_geolocation';

TRUNCATE TABLE bronze.reference_geolocation;

INSERT INTO bronze.reference_geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT


    -- Extract ZIP code prefix
        LEFT(
            raw_data,
            CHARINDEX(',', raw_data) - 1
        ) AS geolocation_zip_code_prefix,


    -- Extract latitude
    SUBSTRING(
        raw_data,
        CHARINDEX(',', raw_data) + 1,

        CHARINDEX(
            ',',
            raw_data,
            CHARINDEX(',', raw_data) + 1
        )
        - CHARINDEX(',', raw_data)
        - 1
    ) AS geolocation_lat,


    -- Extract longitude
    SUBSTRING(
        raw_data,
        CHARINDEX(
            ',',
            raw_data,
            CHARINDEX(',', raw_data) + 1
        ) + 1,

        CHARINDEX(
            ',',
            raw_data,
            CHARINDEX(
                ',',
                raw_data,
                CHARINDEX(',', raw_data) + 1
            ) + 1
        )
        -
        CHARINDEX(
            ',',
            raw_data,
            CHARINDEX(',', raw_data) + 1
        )
        - 1
    ) AS geolocation_lng,


    -- Extract city
    -- Everything after the third comma and before the final comma.
    -- This preserves commas that are part of the city value.
        SUBSTRING(
            raw_data,
            CHARINDEX(
                ',',
                raw_data,
                CHARINDEX(
                    ',',
                    raw_data,
                    CHARINDEX(',', raw_data) + 1
                ) + 1
            ) + 1,

            LEN(raw_data)
                - CHARINDEX(',', REVERSE(raw_data))
                - CHARINDEX(
                    ',',
                    raw_data,
                    CHARINDEX(
                        ',',
                        raw_data,
                        CHARINDEX(',', raw_data) + 1
                    ) + 1
                )
        ) AS geolocation_city,


    -- Extract state
        RIGHT(
            raw_data,
            CHARINDEX(',', REVERSE(raw_data)) - 1
        ) AS geolocation_state

FROM bronze.geolocation_raw;
