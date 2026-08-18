# Olist Brazilian E-Commerce Data Warehouse & Analytics

A SQL Server data warehouse and analytics project built using the **Olist Brazilian E-Commerce dataset**. The project follows a layered data warehouse architecture using **Bronze, Silver, and Gold layers**, followed by exploratory and advanced analytics to generate business insights.

## Project Overview

The objective of this project is to transform raw e-commerce data into a structured analytical data warehouse and use SQL-based analysis to understand:

- Customer purchasing behavior
- Sales and revenue trends
- Product and seller performance
- Delivery performance
- Customer satisfaction
- Payment behavior
- Customer value and retention

The project focuses on data quality, transformation, dimensional modeling, and business-oriented analytics.

---

## Architecture

The data warehouse follows a three-layer architecture:

```text
Bronze Layer
     ↓
Raw data ingestion
     ↓
Silver Layer
     ↓
Cleaning + Standardization + Deduplication
     ↓
Gold Layer
     ↓
Dimensional Modeling + Analytics
```

### Bronze Layer

The Bronze layer stores the source data with minimal transformation. It acts as the initial landing layer for the raw Olist datasets.

### Silver Layer

The Silver layer prepares the data for analytics by applying transformations such as:

- Data type conversion
- Trimming and cleaning text values
- Standardizing categorical values
- Handling missing values
- Removing unwanted characters
- Deduplicating records
- Selecting the latest customer review per order
- Removing duplicate geolocation and order-item records

### Gold Layer

Two Gold-layer designs were developed to demonstrate different fact-table grains and dimensional modeling approaches.

---

# Gold Layer - Version 1

The first Gold-layer design uses an **order-level fact table**.

### Fact Grain

> **One row = one order**

The order-item data is aggregated to the order level, allowing metrics such as:

- Total items
- Total product price
- Total freight value
- Payment information
- Review information

This version is suitable for overall **order-level analysis**.

### Main Gold Objects

- `gold.dim_customer`
- `gold.dim_products`
- `gold.dim_seller`
- `gold.fact_sales`

---

# Gold Layer - Version 2

The second Gold-layer design uses an **order-item-level fact table** to create a more complete Star Schema.

### Fact Grain

> **One row = one product item within an order**

This preserves `order_item_id`, `product_id`, and `seller_id` instead of aggregating all items into a single order row.

This allows the fact table to connect directly with:

- Customer dimension
- Product dimension
- Seller dimension

and supports more detailed product- and seller-level analysis.

## Version 2 Star Schema

![Gold Layer Star Schema Version 2](gold_v2_star_schema.png)

### Dimensions

#### `gold_v2.dim_customer`

Contains one record per unique customer, including:

- Customer key
- Customer unique ID
- ZIP code
- City
- State

Multiple source customer records belonging to the same `customer_unique_id` are consolidated into a single customer record.

#### `gold_v2.dim_products`

Contains product-level attributes such as:

- Product key
- Product ID
- English product category
- Number of product photos
- Weight
- Length
- Height
- Width

#### `gold_v2.dim_seller`

Contains seller-level information including:

- Seller key
- Seller ID
- ZIP code
- City
- State
- Latitude
- Longitude

When multiple geolocation coordinates exist for a ZIP code, one coordinate pair is selected for association with the seller.

#### `gold_v2.fact_sales`

The fact table is maintained at the **order-item grain** and contains:

- Sales key
- Order ID
- Order item ID
- Customer key
- Product key
- Seller key
- Order status
- Order and delivery timestamps
- Product price
- Freight value

---

## Why Two Gold-Layer Versions?

The two versions demonstrate an important data-modeling decision: **fact-table grain**.

### Version 1 - Order Level

```text
One row = One order
```

Useful for high-level metrics such as:

- Number of orders
- Average order value
- Order status distribution
- Order-level payment analysis
- Order-level delivery analysis

However, aggregating order items removes the direct product and seller relationships from the fact table.

### Version 2 - Order Item Level

```text
One row = One product item within an order
```

This preserves product and seller relationships and provides a more natural Star Schema for detailed sales analysis.

For example, an order containing three products produces three fact rows:

```text
Order 1001 | Item 1 | Product A | Seller X
Order 1001 | Item 2 | Product B | Seller X
Order 1001 | Item 3 | Product C | Seller Y
```

Both designs are retained to demonstrate the difference between **order-level and order-item-level modeling**.

---

## Payments and Reviews

Payments and reviews are retained separately from the Version 2 Star Schema.

The Version 2 fact table has an **order-item grain**, while the payment and review data used in the project are maintained at the **order level**.

Keeping them separate avoids introducing duplicated measures when order-level payment or review information is joined to multiple order-item rows.

They can therefore be used independently for specialized payment and customer-satisfaction analysis.

---

# Data Quality & Transformation

The Silver layer includes several data-quality checks and transformations, including:

- Duplicate detection
- NULL-value checks
- Leading/trailing whitespace checks
- Text standardization
- Removal of unwanted quotation marks
- Date and datetime conversion
- Missing-value handling
- Review deduplication
- Geolocation deduplication
- Order-item duplicate handling

Examples of transformations include standardizing values such as:

```text
cash_on_delivery → Cash on delivery
credit_card      → Credit card
```

and converting raw date fields into appropriate SQL Server date/datetime data types.

---

# Exploratory Data Analysis

The EDA phase focuses on understanding the overall structure and behavior of the e-commerce data.

Key areas include:

- Total orders
- Total customers
- Total products
- Total sellers
- Repeat customers
- Monthly order trends
- Customer distribution by state
- Popular products
- Product revenue
- Seller sales
- Payment method usage
- Average order value
- Average review score
- Order-status distribution
- Average delivery time
- Freight cost analysis

---

# Advanced Analytics

The advanced analytics phase moves beyond descriptive statistics to investigate customer behavior, revenue concentration, delivery performance, and payment behavior.

### Customer Analytics

- One-time vs repeat customer analysis
- High-value customer analysis
- RFM metrics: Recency, Frequency, and Monetary value
- Revenue concentration among top customers

### Revenue Analytics

- Monthly revenue trends
- Month-over-month revenue growth

### Delivery Analytics

- Delivery status analysis
- Late-delivery percentage
- Delivery delay vs customer review score
- State-wise delivery performance

### Payment Analytics

- Installment vs single-payment behavior
- Average order value by payment category

These analyses are designed to translate raw transactional data into actionable business insights.

---

# Key SQL Concepts Used

The project demonstrates practical SQL Server concepts including:

- `JOIN`
- `LEFT JOIN`
- `GROUP BY`
- `HAVING`
- `CASE`
- `ISNULL`
- `TRIM`
- `ROW_NUMBER()`
- `RANK()`
- `LAG()`
- `NTILE()`
- `DATEDIFF()`
- `DATEPART()`
- `TRY_CONVERT()`
- Common Table Expressions (CTEs)
- Window functions
- Views
- Aggregations
- Deduplication techniques

---

# Tools & Technologies

- **Database:** Microsoft SQL Server
- **Language:** T-SQL
- **Data Modeling:** Star Schema
- **Analytics:** SQL
- **Version Control:** Git & GitHub

---

# Project Structure

```text
Olist-Data-Warehouse/
│
├── datasets/
│
├── SQL/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── analytics/
│
├── documentation/
│   └── gold_v2_star_schema.png
│
└── README.md
```

---

# Project Outcome

This project demonstrates an end-to-end SQL data analytics workflow:

```text
Raw E-Commerce Data
        ↓
Bronze Layer
        ↓
Data Cleaning & Quality Checks
        ↓
Silver Layer
        ↓
Dimensional Modeling
        ↓
Gold Layer
        ↓
EDA
        ↓
Advanced Analytics
        ↓
Business Insights
```

The project highlights the ability to work with raw transactional data, build a structured data warehouse, design fact and dimension tables based on business grain, and perform analytical SQL to answer business questions.
