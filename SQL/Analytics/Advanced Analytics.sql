/* ============================================================
   ADVANCED ANALYTICS
   Analytics performed in this file are based on version 1
   ============================================================ */


/* ============================================================
   1. CUSTOMER RETENTION BEHAVIOR
   ============================================================ */

-- Classifies customers based on the number of orders placed
-- and calculates the percentage of each customer group.

SELECT 
    customer_type, 
    COUNT(*) AS total_customers, 
    ROUND( 
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 
        2 
    ) AS customer_percentage 
FROM 
( 
    SELECT 
        customer_unique_id, 
        CASE 
            WHEN COUNT(*) = 1 THEN 'One-Time Customer' 
            ELSE 'Repeat Customer' 
        END AS customer_type 
    FROM gold.fact_sales 
    GROUP BY customer_unique_id 
) AS customer_behavior 
GROUP BY customer_type 
ORDER BY total_customers DESC; 



/* ============================================================
   2. HIGH-VALUE CUSTOMER ANALYSIS
   ============================================================ */

-- Identifies the top 10 customers based on their cumulative
-- spending and shows their total number of orders.

SELECT TOP 10 
    customer_unique_id, 
    COUNT(order_id) AS total_orders, 
    SUM(total_price) AS total_spent 
FROM gold.fact_sales 
GROUP BY customer_unique_id 
ORDER BY total_spent DESC; 



/* ============================================================
   3. RFM CUSTOMER METRICS
   ============================================================ */

-- Recency:
-- Number of days since the customer's most recent purchase.
--
-- Frequency:
-- Total number of orders placed by the customer.
--
-- Monetary:
-- Total amount spent by the customer.
--
-- These metrics can later be used for RFM-based
-- customer segmentation.

SELECT 
    customer_unique_id, 
 
    DATEDIFF( 
        DAY, 
        MAX(order_purchase_timestamp), 
        (SELECT MAX(order_purchase_timestamp) 
         FROM gold.fact_sales) 
    ) AS recency, 
 
    COUNT(order_id) AS frequency, 
 
    SUM(total_price) AS monetary 
 
FROM gold.fact_sales 
GROUP BY customer_unique_id; 



/* ============================================================
   4. MONTHLY REVENUE GROWTH
   ============================================================ */

-- Calculates monthly revenue and compares each month with
-- the previous available month using the LAG() function.
--
-- The analysis starts from 2017 to avoid the extremely low
-- transaction volume present in the earliest months.

WITH monthly_sales AS 
( 
    SELECT 
        YEAR(order_purchase_timestamp) AS order_year, 
        MONTH(order_purchase_timestamp) AS order_month, 
        SUM(total_price) AS monthly_revenue 
    FROM gold.fact_sales 
    WHERE order_purchase_timestamp >= '2017-01-01' 
    GROUP BY 
        YEAR(order_purchase_timestamp), 
        MONTH(order_purchase_timestamp) 
), 
sales_with_previous AS 
( 
    SELECT 
        order_year, 
        order_month, 
        monthly_revenue, 
        LAG(monthly_revenue) OVER ( 
            ORDER BY order_year, order_month 
        ) AS previous_month_revenue 
    FROM monthly_sales 
) 
SELECT 
    order_year, 
    order_month, 
    monthly_revenue, 
    previous_month_revenue, 
    ROUND( 
        (monthly_revenue - previous_month_revenue) 
        * 100.0 
        / NULLIF(previous_month_revenue, 0), 
        2 
    ) AS mom_growth_percentage 
FROM sales_with_previous 
ORDER BY 
    order_year, 
    order_month; 



/* ============================================================
   5. REVENUE CONCENTRATION
   ============================================================ */

-- Calculates total spending for each customer, ranks customers
-- into ten revenue-based groups and determines the revenue
-- contribution of the top 10% of customers.

WITH customer_revenue AS 
( 
    SELECT 
        customer_unique_id, 
        SUM(total_price) AS total_spent 
    FROM gold.fact_sales 
    GROUP BY customer_unique_id 
), 
customer_ranked AS 
( 
    SELECT 
        customer_unique_id, 
        total_spent, 
        NTILE(10) OVER ( 
            ORDER BY total_spent DESC 
        ) AS revenue_decile 
    FROM customer_revenue 
) 
SELECT 
    ROUND( 
        SUM(CASE 
            WHEN revenue_decile = 1 THEN total_spent 
            ELSE 0 
        END) * 100.0 
        / SUM(total_spent), 
        2 
    ) AS top_10_percent_revenue_share 
FROM customer_ranked; 



/* ============================================================
   6. DELIVERY PERFORMANCE
   ============================================================ */

-- Classifies orders as On Time, Late or Not Delivered
-- by comparing the actual delivery date with the
-- estimated delivery date.

SELECT 
    delivery_status, 
    COUNT(*) AS total_orders, 
    ROUND( 
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 
        2 
    ) AS order_percentage 
FROM 
( 
    SELECT 
        order_id, 
        CASE 
            WHEN order_delivered_customer_date IS NULL 
                THEN 'Not Delivered' 
            WHEN order_delivered_customer_date > order_estimated_delivery_date 
                THEN 'Late' 
            ELSE 'On Time' 
        END AS delivery_status 
    FROM gold.fact_sales 
) AS delivery_analysis 
GROUP BY delivery_status 
ORDER BY total_orders DESC; 



/* ============================================================
   7. DELIVERY DELAY VS CUSTOMER SATISFACTION
   ============================================================ */

-- Groups delivered orders according to how early or late
-- they were delivered and compares the average review score
-- for each delivery category.

SELECT 
    delivery_category, 
    COUNT(*) AS total_orders, 
    ROUND(AVG(review_score), 2) AS avg_review_score 
FROM 
( 
    SELECT 
        order_id, 
        review_score, 
        CASE 
            WHEN DATEDIFF( 
                    DAY, 
                    order_estimated_delivery_date, 
                    order_delivered_customer_date 
                 ) < 0 
                THEN 'Delivered Early' 
 
            WHEN DATEDIFF( 
                    DAY, 
                    order_estimated_delivery_date, 
                    order_delivered_customer_date 
                 ) = 0 
                THEN 'Delivered On Time' 
 
            WHEN DATEDIFF( 
                    DAY, 
                    order_estimated_delivery_date, 
                    order_delivered_customer_date 
                 ) BETWEEN 1 AND 3 
                THEN '1-3 Days Late' 
 
            WHEN DATEDIFF( 
                    DAY, 
                    order_estimated_delivery_date, 
                    order_delivered_customer_date 
                 ) BETWEEN 4 AND 7 
                THEN '4-7 Days Late' 
 
            ELSE 'More Than 7 Days Late' 
        END AS delivery_category 
 
    FROM gold.fact_sales 
    WHERE 
        order_delivered_customer_date IS NOT NULL 
        AND order_estimated_delivery_date IS NOT NULL 
        AND review_score > 0 
) AS delivery_analysis 
GROUP BY delivery_category 
ORDER BY avg_review_score DESC; 



/* ============================================================
   8. DELIVERY PERFORMANCE BY CUSTOMER STATE
   ============================================================ */

-- Compares delivery performance across customer states using
-- total delivered orders, late orders, late-delivery percentage
-- and average delivery time.

SELECT 
    c.customer_state, 
    COUNT(f.order_id) AS delivered_orders, 
 
    SUM( 
        CASE 
            WHEN f.order_delivered_customer_date > f.order_estimated_delivery_date 
            THEN 1 
            ELSE 0 
        END 
    ) AS late_orders, 
 
    ROUND( 
        SUM( 
            CASE 
                WHEN f.order_delivered_customer_date > f.order_estimated_delivery_date 
                THEN 1 
                ELSE 0 
            END 
        ) * 100.0 / COUNT(f.order_id), 
        2 
    ) AS late_delivery_percentage, 
 
    ROUND( 
        AVG( 
            DATEDIFF( 
                DAY, 
                f.order_purchase_timestamp, 
                f.order_delivered_customer_date 
            ) * 1.0 
        ), 
        2 
    ) AS avg_delivery_days 
 
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_customer AS c 
    ON f.customer_unique_id = c.customer_unique_id 
 
WHERE 
    f.order_delivered_customer_date IS NOT NULL 
    AND f.order_estimated_delivery_date IS NOT NULL 
 
GROUP BY c.customer_state 
ORDER BY late_delivery_percentage DESC; 



/* ============================================================
   9. INSTALLMENT PAYMENT ANALYSIS
   ============================================================ */

-- Compares orders paid through installments with single-payment
-- orders based on average order value and average payment value.

SELECT 
    CASE 
        WHEN total_payment_installments > 1 
            THEN 'Installment Payment' 
        ELSE 'Single Payment' 
    END AS payment_category, 
 
    COUNT(*) AS total_orders, 
 
    ROUND(AVG(total_price), 2) AS average_order_value, 
 
    ROUND(AVG(total_payment_value), 2) AS average_payment_value 
 
FROM gold.fact_sales 
 
GROUP BY 
    CASE 
        WHEN total_payment_installments > 1 
            THEN 'Installment Payment' 
        ELSE 'Single Payment' 
    END 
 
ORDER BY average_order_value DESC;
