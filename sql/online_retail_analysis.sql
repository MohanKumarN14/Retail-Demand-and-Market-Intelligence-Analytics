-- ============================================================
-- Online Retail — Schema & Business Analysis Queries
-- Matches your actual cleaned dataset columns:
-- Invoice, StockCode, Description, Description_clean, Quantity,
-- InvoiceDate, Price, Price_clean, Customer_ID, Country,
-- is_cancelled, is_stock_adjustment, original_was_cancelled,
-- exclude_from_demand, is_price_outlier
--
-- Written for SQLite. For PostgreSQL: replace strftime() with
-- TO_CHAR(), and INTEGER flag columns with BOOLEAN if preferred.
-- ============================================================


-- ------------------------------------------------------------
-- 1. SCHEMA
-- ------------------------------------------------------------
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    Invoice                    TEXT,
    StockCode                  TEXT,
    Description                TEXT,
    Description_clean          TEXT,
    Quantity                   INTEGER,
    InvoiceDate                 TEXT,     -- 'YYYY-MM-DD HH:MM:SS'
    Price                       REAL,
    Price_clean                 REAL,
    Customer_ID                  REAL,
    Country                     TEXT,
    is_cancelled                 INTEGER,  -- 0/1
    is_stock_adjustment           INTEGER,
    original_was_cancelled        INTEGER,
    exclude_from_demand            INTEGER,
    is_price_outlier                 INTEGER
);

-- Load directly from pandas — booleans convert to 0/1 automatically:
-- df.to_sql("orders", conn, if_exists="replace", index=False)


-- ------------------------------------------------------------
-- 2. DATA QUALITY OVERVIEW — what your cleaning flags caught
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_rows,
    SUM(is_cancelled) AS cancelled_rows,
    SUM(is_stock_adjustment) AS stock_adjustment_rows,
    SUM(exclude_from_demand) AS excluded_from_demand_rows,
    SUM(is_price_outlier) AS price_outlier_rows,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id
FROM orders;


-- ------------------------------------------------------------
-- 3. GROSS VS DEMAND-ELIGIBLE REVENUE
-- Great insight to highlight: "raw revenue looks like X, but
-- after removing cancellations/adjustments/outliers, true
-- demand is Y" — shows you understand data quality, not just SQL.
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(Quantity * Price_clean), 2) AS gross_revenue_all_rows,
    ROUND(SUM(CASE WHEN exclude_from_demand = 0 THEN Quantity * Price_clean ELSE 0 END), 2) AS demand_eligible_revenue
FROM orders;


-- ------------------------------------------------------------
-- 4. MONTHLY REVENUE TREND (demand-eligible only)
-- ------------------------------------------------------------
SELECT
    strftime('%Y-%m', InvoiceDate) AS month,
    ROUND(SUM(Quantity * Price_clean), 2) AS revenue,
    COUNT(DISTINCT Invoice) AS num_orders
FROM orders
WHERE exclude_from_demand = 0
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 5. MONTH-OVER-MONTH GROWTH (window function: LAG)
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        strftime('%Y-%m', InvoiceDate) AS month,
        SUM(Quantity * Price_clean) AS revenue
    FROM orders
    WHERE exclude_from_demand = 0
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month), 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- 6. TOP 10 PRODUCTS BY REVENUE (demand-eligible only)
-- ------------------------------------------------------------
SELECT
    StockCode,
    Description_clean,
    ROUND(SUM(Quantity * Price_clean), 2) AS revenue,
    SUM(Quantity) AS units_sold
FROM orders
WHERE exclude_from_demand = 0
GROUP BY StockCode, Description_clean
ORDER BY revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 7. REVENUE BY COUNTRY
-- ------------------------------------------------------------
SELECT
    Country,
    ROUND(SUM(Quantity * Price_clean), 2) AS revenue,
    COUNT(DISTINCT Customer_ID) AS num_customers
FROM orders
WHERE exclude_from_demand = 0
GROUP BY Country
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- 8. TOP-SELLING PRODUCT PER COUNTRY (window function: RANK)
-- ------------------------------------------------------------
WITH country_product_sales AS (
    SELECT
        Country,
        StockCode,
        Description_clean,
        SUM(Quantity * Price_clean) AS revenue,
        RANK() OVER (PARTITION BY Country ORDER BY SUM(Quantity * Price_clean) DESC) AS rnk
    FROM orders
    WHERE exclude_from_demand = 0
    GROUP BY Country, StockCode, Description_clean
)
SELECT Country, StockCode, Description_clean, ROUND(revenue, 2) AS revenue
FROM country_product_sales
WHERE rnk = 1
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- 9. CANCELLATION RATE TREND
-- Uses is_cancelled — a data-quality angle most portfolio
-- projects skip entirely.
-- ------------------------------------------------------------
SELECT
    strftime('%Y-%m', InvoiceDate) AS month,
    COUNT(*) AS total_transactions,
    SUM(is_cancelled) AS cancelled_transactions,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 10. REPEAT VS ONE-TIME CUSTOMERS (CTE)
-- ------------------------------------------------------------
WITH customer_orders AS (
    SELECT
        Customer_ID,
        COUNT(DISTINCT Invoice) AS order_count
    FROM orders
    WHERE exclude_from_demand = 0 AND Customer_ID IS NOT NULL
    GROUP BY Customer_ID
)
SELECT
    CASE WHEN order_count = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    COUNT(*) AS num_customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_orders), 1) AS pct_of_customers
FROM customer_orders
GROUP BY customer_type;


-- ------------------------------------------------------------
-- 11. CUSTOMER LIFETIME VALUE — TOP 20 SPENDERS
-- ------------------------------------------------------------
SELECT
    Customer_ID,
    Country,
    ROUND(SUM(Quantity * Price_clean), 2) AS lifetime_value,
    COUNT(DISTINCT Invoice) AS num_orders,
    MIN(InvoiceDate) AS first_purchase,
    MAX(InvoiceDate) AS last_purchase
FROM orders
WHERE exclude_from_demand = 0 AND Customer_ID IS NOT NULL
GROUP BY Customer_ID, Country
ORDER BY lifetime_value DESC
LIMIT 20;
