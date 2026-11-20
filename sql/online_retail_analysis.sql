CREATE DATABASE IF NOT EXISTS online_retail_db;
USE online_retail_db;

CREATE TABLE IF NOT EXISTS online_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(12,4),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    @InvoiceDate,
    UnitPrice,
    @CustomerID,
    Country
)
SET
    InvoiceDate = STR_TO_DATE(@InvoiceDate, '%d-%m-%Y %H:%i'),
    CustomerID = NULLIF(@CustomerID, '');

SELECT *
FROM online_retail_db.online_retail
LIMIT 10;

SELECT COUNT(*) AS total_records
FROM online_retail_db.online_retail;

SELECT
    COUNT(*) AS missing_customer_id
FROM online_retail_db.online_retail
WHERE CustomerID IS NULL;

SELECT
    COUNT(*) AS missing_description
FROM online_retail_db.online_retail
WHERE Description IS NULL
   OR Description = '';
   
SELECT
    COUNT(*) AS non_positive_quantity
FROM online_retail_db.online_retail
WHERE Quantity <= 0;

SELECT
    COUNT(*) AS non_positive_unit_price
FROM online_retail_db.online_retail
WHERE UnitPrice <= 0;

SELECT
    SUM(CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END) AS zero_prices,
    SUM(CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END) AS negative_prices
FROM online_retail_db.online_retail;

SELECT
    COUNT(CASE WHEN UnitPrice = 0 THEN 1 END) AS zero_prices,
    COUNT(CASE WHEN UnitPrice < 0 THEN 1 END) AS negative_prices,
    COUNT(CASE WHEN UnitPrice > 0 AND UnitPrice < 0.005 THEN 1 END) AS small_positive_prices,
    COUNT(CASE WHEN UnitPrice <= 0 THEN 1 END) AS non_positive_prices
FROM online_retail_db.online_retail;

SELECT
    COUNT(*) AS total_unique_rows
FROM (
    SELECT DISTINCT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    FROM online_retail_db.online_retail
) AS unique_data;
        
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    COUNT(*) AS occurrence_count
FROM online_retail_db.online_retail
GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 10;

CREATE TABLE online_retail_db.online_retail_clean
LIKE online_retail_db.online_retail;

INSERT INTO online_retail_db.online_retail_clean
SELECT *
FROM online_retail_db.online_retail;

SELECT *
FROM online_retail_db.online_retail_clean
LIMIT 10;

SELECT
    'Original Table' AS table_name,
    COUNT(*) AS total_records
FROM online_retail_db.online_retail

UNION ALL

SELECT
    'Clean Table' AS table_name,
    COUNT(*) AS total_records
FROM online_retail_db.online_retail_clean;

SELECT
    SUM(InvoiceNo IS NULL OR InvoiceNo = '') AS missing_invoice,
    SUM(StockCode IS NULL OR StockCode = '') AS missing_stock,
    SUM(Description IS NULL OR Description = '') AS missing_description,
    SUM(InvoiceDate IS NULL) AS missing_date,
    SUM(CustomerID IS NULL OR CustomerID = '') AS missing_customer
FROM online_retail_db.online_retail_clean;

SELECT
    COUNT(*) AS missing_description_records,
    SUM(CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END) AS zero_price_records,
    SUM(CASE WHEN UnitPrice > 0 THEN 1 ELSE 0 END) AS positive_price_records,
    SUM(CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END) AS negative_price_records
FROM online_retail_db.online_retail_clean
WHERE Description IS NULL
   OR TRIM(Description) = '';
   
SELECT
    COUNT(*) AS missing_customer_records,
    SUM(CASE WHEN Quantity > 0 AND UnitPrice > 0
        THEN 1 ELSE 0 END) AS valid_sales_records,
    SUM(CASE WHEN Quantity <= 0 OR UnitPrice <= 0
        THEN 1 ELSE 0 END) AS non_sales_records
FROM online_retail_db.online_retail_clean
WHERE CustomerID IS NULL
   OR TRIM(CustomerID) = '';
  
SELECT
    COUNT(*) AS cancelled_records,
    COUNT(DISTINCT InvoiceNo) AS cancelled_invoices,
    ROUND(SUM(Quantity * UnitPrice), 2) AS cancellation_value
FROM online_retail_db.online_retail_clean
WHERE InvoiceNo LIKE 'C%';

SELECT
    COUNT(*) AS negative_quantity_records,
    COUNT(DISTINCT InvoiceNo) AS affected_invoices,
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_value
FROM online_retail_db.online_retail_clean
WHERE Quantity < 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_db.online_retail_clean
WHERE UnitPrice < 0;

SELECT
    COUNT(*) AS total_zero_price,
    SUM(CASE WHEN Quantity > 0 THEN 1 ELSE 0 END) AS positive_quantity,
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS negative_quantity,
    SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS zero_quantity
FROM online_retail_db.online_retail_clean
WHERE UnitPrice = 0;

SELECT
    COUNT(*) AS eligible_sales_records
FROM online_retail_db.online_retail_clean
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    ROUND(SUM(Quantity * UnitPrice), 2) AS gross_sales_revenue
FROM online_retail_db.online_retail_clean
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    ROUND(SUM(CASE
        WHEN CustomerID IS NULL OR TRIM(CustomerID) = ''
        THEN Quantity * UnitPrice
        ELSE 0
    END), 2) AS anonymous_revenue,

    ROUND(SUM(CASE
        WHEN CustomerID IS NOT NULL AND TRIM(CustomerID) <> ''
        THEN Quantity * UnitPrice
        ELSE 0
    END), 2) AS identified_revenue,

    ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue

FROM online_retail_db.online_retail_clean
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    ROUND(SUM(
        CASE
            WHEN Quantity > 0
                 AND UnitPrice > 0
                 AND InvoiceNo NOT LIKE 'C%'
            THEN Quantity * UnitPrice
            ELSE 0
        END
    ), 2) AS gross_sales,

    ROUND(SUM(
        CASE
            WHEN InvoiceNo LIKE 'C%'
            THEN Quantity * UnitPrice
            ELSE 0
        END
    ), 2) AS cancellation_value,

    ROUND(SUM(
        CASE
            WHEN Quantity > 0
                 AND UnitPrice > 0
                 AND InvoiceNo NOT LIKE 'C%'
            THEN Quantity * UnitPrice
            WHEN InvoiceNo LIKE 'C%'
            THEN Quantity * UnitPrice
            ELSE 0
        END
    ), 2) AS net_sales

FROM online_retail_db.online_retail_clean;

SELECT
    SUM(occurrences - 1) AS extra_duplicate_rows,
    ROUND(
        SUM((occurrences - 1) * Quantity * UnitPrice),
        2
    ) AS duplicate_revenue_impact
FROM (
    SELECT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country,
        COUNT(*) AS occurrences
    FROM online_retail_db.online_retail_clean
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    HAVING COUNT(*) > 1
) AS duplicate_groups;

SELECT
    COALESCE(SUM(occurrences - 1), 0) AS duplicate_cancellation_rows,
    COALESCE(
        ROUND(SUM((occurrences - 1) * Quantity * UnitPrice), 2),
        0
    ) AS duplicate_cancellation_value
FROM (
    SELECT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country,
        COUNT(*) AS occurrences
    FROM online_retail_db.online_retail_clean
    WHERE InvoiceNo LIKE 'C%'
    GROUP BY
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    HAVING COUNT(*) > 1
) AS duplicate_groups;
    
CREATE TABLE online_retail_db.online_retail_backup
LIKE online_retail_db.online_retail_clean;

INSERT INTO online_retail_db.online_retail_backup
SELECT *
FROM online_retail_db.online_retail_clean;

SELECT *
FROM online_retail_db.online_retail_backup
LIMIT 10;

SELECT
    (SELECT COUNT(*)
     FROM online_retail_db.online_retail_clean)
        AS original_rows,

    (SELECT COUNT(*)
     FROM online_retail_db.online_retail_backup)
        AS backup_rows;
        
CREATE TABLE online_retail_db.online_retail_deduplicated
LIKE online_retail_db.online_retail_clean;

INSERT INTO online_retail_db.online_retail_deduplicated
SELECT DISTINCT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_db.online_retail_clean;

SELECT *
FROM online_retail_db.online_retail_deduplicated
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    (
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT
                InvoiceNo,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                UnitPrice,
                CustomerID,
                Country
            FROM online_retail_db.online_retail_deduplicated
        ) AS unique_records
    ) AS unique_rows
FROM online_retail_db.online_retail_deduplicated;

SELECT
    ROUND(
        SUM(
            CASE
                WHEN Quantity > 0
                     AND UnitPrice > 0
                     AND InvoiceNo NOT LIKE 'C%'
                THEN Quantity * UnitPrice
                WHEN InvoiceNo LIKE 'C%'
                THEN Quantity * UnitPrice
                ELSE 0
            END
        ), 2
    ) AS net_sales
FROM online_retail_db.online_retail_deduplicated;

SELECT
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN CustomerID IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_customer_id,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN CustomerID IS NULL
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_percentage
FROM online_retail_db.online_retail_deduplicated;

SELECT
    COUNT(*) AS anonymous_sales_rows,
    ROUND(
        SUM(Quantity * UnitPrice),
        2
    ) AS anonymous_gross_sales
FROM online_retail_db.online_retail_deduplicated
WHERE CustomerID IS NULL
  AND Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    COUNT(*) AS blank_customer_ids
FROM online_retail_db.online_retail_deduplicated
WHERE CustomerID IS NOT NULL
  AND TRIM(CustomerID) = '';
  
SELECT
    COUNT(*) AS blank_description_rows,
    SUM(
        CASE
            WHEN Quantity > 0
                 AND UnitPrice > 0
                 AND InvoiceNo NOT LIKE 'C%'
            THEN 1
            ELSE 0
        END
    ) AS valid_sales_rows,
    ROUND(
        SUM(
            CASE
                WHEN Quantity > 0
                     AND UnitPrice > 0
                     AND InvoiceNo NOT LIKE 'C%'
                THEN Quantity * UnitPrice
                ELSE 0
            END
        ), 2
    ) AS gross_sales_impact
FROM online_retail_db.online_retail_deduplicated
WHERE Description IS NULL
   OR TRIM(Description) = '';
   
CREATE TABLE online_retail_db.online_retail_final
LIKE online_retail_db.online_retail_deduplicated;

INSERT INTO online_retail_db.online_retail_final
SELECT *
FROM online_retail_db.online_retail_deduplicated
WHERE Description IS NOT NULL
  AND TRIM(Description) <> '';
  
SELECT *
FROM online_retail_db.online_retail_final
LIMIT 10;
  
SELECT
    COUNT(*) AS total_rows,
    ROUND(
        SUM(
            CASE
                WHEN Quantity > 0
                     AND UnitPrice > 0
                     AND InvoiceNo NOT LIKE 'C%'
                THEN Quantity * UnitPrice
                WHEN InvoiceNo LIKE 'C%'
                THEN Quantity * UnitPrice
                ELSE 0
            END
        ), 2
    ) AS net_sales
FROM online_retail_db.online_retail_final;

SELECT
    COUNT(*) AS negative_quantity_rows,
    SUM(
        CASE
            WHEN InvoiceNo LIKE 'C%' THEN 1
            ELSE 0
        END
    ) AS cancellation_rows,
    SUM(
        CASE
            WHEN InvoiceNo NOT LIKE 'C%' THEN 1
            ELSE 0
        END
    ) AS other_negative_rows
FROM online_retail_db.online_retail_final
WHERE Quantity < 0;

SELECT
    COUNT(*) AS other_negative_rows,
    SUM(
        CASE
            WHEN UnitPrice = 0 THEN 1
            ELSE 0
        END
    ) AS zero_price_rows,
    SUM(
        CASE
            WHEN UnitPrice <> 0 THEN 1
            ELSE 0
        END
    ) AS nonzero_price_rows,
    ROUND(
        SUM(Quantity * UnitPrice),
        2
    ) AS total_value
FROM online_retail_db.online_retail_final
WHERE Quantity < 0
  AND InvoiceNo NOT LIKE 'C%';
  
SELECT
    COUNT(*) AS zero_price_rows,
    SUM(
        CASE
            WHEN Quantity > 0 THEN 1
            ELSE 0
        END
    ) AS positive_quantity_rows,
    SUM(
        CASE
            WHEN Quantity < 0 THEN 1
            ELSE 0
        END
    ) AS negative_quantity_rows
FROM online_retail_db.online_retail_final
WHERE UnitPrice = 0;
  
  SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS total_value
FROM online_retail_db.online_retail_final
WHERE UnitPrice < 0;

SELECT
    CASE
        WHEN InvoiceNo LIKE 'C%'
            THEN 'Cancellation'
        WHEN Quantity > 0 AND UnitPrice > 0
            THEN 'Paid Sale'
        ELSE 'Other / Non-Sales'
    END AS transaction_type,
    COUNT(*) AS total_rows,
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_value
FROM online_retail_db.online_retail_final
GROUP BY
    CASE
        WHEN InvoiceNo LIKE 'C%'
            THEN 'Cancellation'
        WHEN Quantity > 0 AND UnitPrice > 0
            THEN 'Paid Sale'
        ELSE 'Other / Non-Sales'
    END
ORDER BY total_rows DESC;

CREATE VIEW online_retail_db.vw_sales_analysis AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    ROUND(Quantity * UnitPrice, 2) AS Revenue,
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation'
        ELSE 'Paid Sale'
    END AS TransactionType
FROM online_retail_db.online_retail_final
WHERE
    (Quantity > 0
     AND UnitPrice > 0
     AND InvoiceNo NOT LIKE 'C%')
    OR
    (InvoiceNo LIKE 'C%'
     AND Quantity < 0
     AND UnitPrice > 0);
     
SELECT *
FROM online_retail_db.vw_sales_analysis
LIMIT 10;
     
SELECT
    COUNT(*) AS total_rows,
    SUM(
        CASE
            WHEN TransactionType = 'Paid Sale' THEN 1
            ELSE 0
        END
    ) AS paid_sales_rows,
    SUM(
        CASE
            WHEN TransactionType = 'Cancellation' THEN 1
            ELSE 0
        END
    ) AS cancellation_rows,
    ROUND(SUM(Revenue), 2) AS net_sales
FROM online_retail_db.vw_sales_analysis;

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
    ROUND(SUM(Revenue), 2) AS net_sales
FROM online_retail_db.vw_sales_analysis
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY sales_month;

SELECT
    MIN(InvoiceDate) AS first_transaction,
    MAX(InvoiceDate) AS last_transaction
FROM online_retail_db.vw_sales_analysis;

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
        ROUND(SUM(Revenue), 2) AS net_sales
    FROM online_retail_db.vw_sales_analysis
    WHERE InvoiceDate >= '2010-12-01'
      AND InvoiceDate < '2011-12-01'
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
),
sales_growth AS (
    SELECT
        sales_month,
        net_sales,
        LAG(net_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    net_sales,
    previous_month_sales,
    ROUND(
        (net_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS mom_growth_pct
FROM sales_growth
ORDER BY sales_month;