/*
===============================================================================
Database & Schema Initialization
===============================================================================

Project:
    Brazilian E-Commerce Data Warehouse, EDA & Advanced Analytics

Description:
    This script creates the SQL Server database and the three schemas required
    for the Medallion Architecture used in this Data Warehouse project.

Architecture:
    
    Source CSV Files
           |
           v
       BRONZE
    Raw Source Data
           |
           v
        SILVER
    Cleaned & Standardized Data
           |
           v
         GOLD
    Business-Ready Data
    (Fact & Dimension Tables)

Bronze:
    Stores raw data ingested from the Olist CSV source files.

Silver:
    Stores cleaned, standardized, validated, and integrated data.

Gold:
    Stores business-ready data models designed for EDA and Advanced Analytics.

Note:
    The database is dropped and recreated during development to provide a
    clean environment for rebuilding the Data Warehouse.
===============================================================================
*/


/*
===============================================================================
1. Switch to the master database
===============================================================================

Why?
    DataWarehouse may not exist yet, so we cannot initially USE it.
    The master database is used to manage databases at the SQL Server level.
===============================================================================
*/

USE master;
GO


/*
===============================================================================
2. Drop Existing DataWarehouse Database
===============================================================================

Purpose:
    If DataWarehouse already exists, terminate active connections and remove
    the existing database so that the project can be rebuilt from scratch.

Why?
    During development, we may need to recreate tables, schemas, or ETL logic.
    Recreating the database provides a clean environment.

WARNING:
    DROP DATABASE permanently deletes everything inside DataWarehouse.
    This should only be used for development/testing, NOT production databases.
===============================================================================
*/

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN

    -- Disconnect active users and roll back their running transactions.
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Permanently remove the existing DataWarehouse database.
    DROP DATABASE DataWarehouse;

END;
GO


/*
===============================================================================
3. Create the DataWarehouse Database
===============================================================================

Purpose:
    Creates a new empty database that will contain the complete Data Warehouse.

Why?
    The Data Warehouse needs a dedicated database to separate analytical data
    from operational/source systems.
===============================================================================
*/

CREATE DATABASE DataWarehouse;
GO


/*
===============================================================================
4. Switch to the DataWarehouse Database
===============================================================================

Purpose:
    All schemas and tables created from this point onward will belong to the
    DataWarehouse database.
===============================================================================
*/

USE DataWarehouse;
GO


/*
===============================================================================
5. Create Bronze Schema
===============================================================================

Purpose:
    Stores raw data loaded directly from the Olist CSV source files.

Characteristics:
    - Minimal transformation
    - Preserves source data
    - Used as the initial landing layer
===============================================================================
*/

CREATE SCHEMA bronze;
GO


/*
===============================================================================
6. Create Silver Schema
===============================================================================

Purpose:
    Stores cleaned, standardized, validated, and integrated data.

Typical transformations:
    - Handle NULL values
    - Remove duplicates
    - Standardize formats
    - Correct data types
    - Integrate related source tables
    - Apply data quality rules
===============================================================================
*/

CREATE SCHEMA silver;
GO


/*
===============================================================================
7. Create Gold Schema
===============================================================================

Purpose:
    Stores business-ready data models used for analysis.

Typical objects:
    - Fact tables
    - Dimension tables
    - Aggregated business data
    - Analytical datasets

Example:
    gold.fact_orders
    gold.dim_customers
    gold.dim_products
===============================================================================
*/

CREATE SCHEMA gold;
GO
